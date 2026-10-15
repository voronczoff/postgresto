#!/usr/bin/env bash
# Apply Liquibase changelogs (host liquibase CLI).
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

# This variable configures the Docker image, not the local Liquibase CLI.
unset LIQUIBASE_VERSION || true

PGHOST=${PGHOST:-localhost}
PGPORT=${PGPORT:-5432}
PGUSER=${PGUSER:-postgres}
PGPASSWORD=${PGPASSWORD:-postgres}
PGDATABASE=${PGDATABASE:-postgresto-local}
JDBC_URL="jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}"

if ! command -v liquibase >/dev/null 2>&1; then
  echo "liquibase not found on PATH (use ./applyLiquibaseDocker.sh instead)" >&2
  exit 1
fi

# Unset so Liquibase does not treat LIQUIBASE_CONTEXTS as a framework env var.
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

liquibase "${ARGS[@]}" update "${LIQUIBASE_CHANGELOG_PARAMS[@]}"
