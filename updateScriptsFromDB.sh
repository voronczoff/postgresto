#!/usr/bin/env bash
# Export the configured Postgres config, menu, and view rows to Liquibase SQL.
# Connection settings come from the repository-root .env.
# Stale per-ID files are removed; their IDs are kept in a DELETE manifest.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing $ROOT/.env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. "$ROOT/.env"
set +a

: "${PGDATABASE:?PGDATABASE must be set in .env}"
: "${PGUSER:?PGUSER must be set in .env}"
: "${PGPASSWORD:?PGPASSWORD must be set in .env}"

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGUSER PGDATABASE PGPASSWORD
SCHEMA="${SCHEMA:-postgresto}"

echo "Exporting ${PGDATABASE} (${PGHOST}:${PGPORT}) schema ${SCHEMA}"
echo "Tables: ${SCHEMA}.view, ${SCHEMA}.menu, ${SCHEMA}.config"

python3 - "$ROOT" "$SCHEMA" <<'PY'
import hashlib
import json
import re
import subprocess
import sys
import textwrap
from pathlib import Path

root = Path(sys.argv[1])
schema = sys.argv[2]


def ident(value):
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_$]*", value):
        raise SystemExit(f"Invalid PostgreSQL identifier: {value!r}")
    return '"' + value.replace('"', '""') + '"'


def sql_literal(value):
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def fetch(table):
    relation = f"{ident(schema)}.{ident(table)}"
    query = f"SELECT row_to_json(r)::text FROM {relation} AS r ORDER BY id"
    result = subprocess.run(
        ["psql", "-X", "-q", "-A", "-t", "-v", "ON_ERROR_STOP=1", "-c", query],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return [json.loads(line) for line in result.stdout.splitlines() if line]


def existing_changeset(path, prefix, fallback):
    if path.exists():
        match = re.search(r"^--changeset framework:([^ ]+)", path.read_text(), re.M)
        if match:
            return match.group(1)
    return f"{prefix}-{hashlib.sha1(fallback.encode()).hexdigest()[:10]}"


def filename_for(value):
    name = str(value)
    if not name or name in {".", ".."} or "/" in name or "\\" in name:
        raise SystemExit(f"Cannot safely map database id to a filename: {name!r}")
    return name + ".sql"


def write_rows(folder, rows, kind, table_name):
    directory = root / "scripts" / folder
    directory.mkdir(parents=True, exist_ok=True)
    generated = set()
    active_ids = set()
    for row in rows:
        row_id = row.get("id")
        if row_id is None:
            raise SystemExit(f"Row in {folder} has no id")
        active_ids.add(str(row_id))
        path = directory / filename_for(row_id)
        generated.add(path.name)
        change_id = existing_changeset(path, f"seed-{kind}", str(row_id))
        jsondata = json.dumps(row.get("jsondata"), ensure_ascii=False, indent=2)
        delimiter = "$json$"
        while delimiter in jsondata:
            delimiter = "$json_" + hashlib.sha1((str(row_id) + delimiter).encode()).hexdigest()[:10] + "$"
        fields = ["id", "jsondata"]
        values = [sql_literal(row_id), f"{delimiter}\n{jsondata}\n{delimiter}::jsonb"]
        columns_sql = ", ".join(fields)
        json_sql = textwrap.indent(values[1], "  ")
        path.write_text(
            "--liquibase formatted sql\n"
            f"--changeset framework:{change_id} runOnChange:true splitStatements:false\n"
            f"INSERT INTO postgresto.{table_name}\n"
            f"  ({columns_sql})\n"
            f"VALUES (\n  {values[0]},\n{json_sql}\n)\n"
            "ON CONFLICT (id) DO UPDATE SET\n"
            "  jsondata = EXCLUDED.jsondata;\n"
        )

    manifest = directory / "000_deleted_ids.sql"
    removed_ids = set()
    if manifest.exists():
        match = re.search(r"^-- removed-ids: (.+)$", manifest.read_text(), re.M)
        if match:
            removed_ids.update(json.loads(match.group(1)))

    for path in directory.glob("*.sql"):
        if path == manifest:
            continue
        if path.name not in generated:
            contents = path.read_text()
            match = re.search(r"^--changeset framework:([^ ]+)", contents, re.M)
            if not match or not match.group(1).startswith(f"seed-{kind}-"):
                continue
            removed_ids.add(path.name[:-4])
            path.unlink()

    removed_ids.difference_update(active_ids)
    if removed_ids:
        table = f"postgresto.{table_name}"
        ids_sql = ",\n  ".join(sql_literal(value) for value in sorted(removed_ids))
        manifest.write_text(
            "--liquibase formatted sql\n"
            f"--changeset framework:sync-deleted-{kind}-ids runOnChange:true splitStatements:false\n"
            f"-- removed-ids: {json.dumps(sorted(removed_ids), ensure_ascii=False)}\n"
            f"DELETE FROM {table}\n"
            f"WHERE id IN (\n  {ids_sql}\n);\n"
        )
        print(f"{folder}: delete manifest contains {len(removed_ids)} removed id(s)")
    elif manifest.exists():
        manifest.unlink()
    print(f"{folder}: wrote {len(rows)} row(s)")


views = fetch("view")
menus = fetch("menu")
configs = fetch("config")
write_rows("views", views, "view", "view")
write_rows("menu", menus, "menu", "menu")
write_rows("config", configs, "config", "config")
PY

# Refresh the search index after applying the exported index configuration.
printf '\nSELECT * FROM postgresto.search_refresh();\n' >> scripts/config/index.sql

echo "Done."
