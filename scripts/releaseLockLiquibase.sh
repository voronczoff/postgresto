#!/usr/bin/env bash
# Release a stuck Liquibase lock on local Postgres.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$ROOT/.." && pwd)"
cd "$ROOT"

if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$REPO_ROOT/.env"
  set +a
fi

PGHOST=${PGHOST:-localhost}
PGPORT=${PGPORT:-5432}
PGUSER=${PGUSER:-postgres}
PGPASSWORD=${PGPASSWORD:-postgres}
PGDATABASE=${PGDATABASE:-postgresto-local}
JDBC_URL="jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}"

liquibase \
  --url="$JDBC_URL" \
  --username="$PGUSER" \
  --password="$PGPASSWORD" \
  release-locks
