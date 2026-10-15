#!/usr/bin/env bash
# Clear Liquibase checksums then apply (local).
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

unset LIQUIBASE_CONTEXTS || true

# shellcheck disable=SC1091
. "$ROOT/liquibaseChangelogParams.sh"

ARGS=(
  --url="$JDBC_URL"
  --username="$PGUSER"
  --password="$PGPASSWORD"
  --defaults-file=liquibase.properties
  --search-path=.
)
if [ -n "${CONTEXTS:-}" ]; then
  ARGS+=(--contexts="$CONTEXTS")
fi

liquibase "${ARGS[@]}" clearCheckSums
liquibase "${ARGS[@]}" update "${LIQUIBASE_CHANGELOG_PARAMS[@]}"
