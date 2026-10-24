#!/usr/bin/env bash
# Apply Liquibase changelogs via the official liquibase Docker image.
# Use this when the liquibase CLI is not installed locally.
#
# Env (from repo-root .env or shell):
#   PGHOST / PGPORT / PGUSER / PGPASSWORD / PGDATABASE
#   CONTEXTS (optional Liquibase context filter)
#   LIQUIBASE_IMAGE (default: liquibase/liquibase:$LIQUIBASE_VERSION)
#   LIQUIBASE_VERSION (default: 4.33)
#   DOCKER_DB_HOST (default: host.docker.internal) — replaces localhost in JDBC URL
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
LIQUIBASE_VERSION="${LIQUIBASE_VERSION:-4.33}"
LIQUIBASE_IMAGE="${LIQUIBASE_IMAGE:-liquibase/liquibase:${LIQUIBASE_VERSION}}"
DOCKER_DB_HOST="${DOCKER_DB_HOST:-host.docker.internal}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found on PATH" >&2
  exit 1
fi


# From inside the container, localhost is the container — rewrite to the host.
DOCKER_DB_URL="$JDBC_URL"
DOCKER_DB_URL="${DOCKER_DB_URL//localhost/$DOCKER_DB_HOST}"
DOCKER_DB_URL="${DOCKER_DB_URL//127.0.0.1/$DOCKER_DB_HOST}"

unset LIQUIBASE_CONTEXTS || true

# shellcheck disable=SC1091
. "$ROOT/liquibaseChangelogParams.sh"

ARGS=(
  --url="$DOCKER_DB_URL"
  --username="$PGUSER"
  --password="$PGPASSWORD"
  --defaults-file=liquibase.properties
  --search-path=/liquibase/changelog
)
if [ -n "${CONTEXTS:-}" ]; then
  ARGS+=(--contexts="$CONTEXTS")
fi

docker run --rm \
  --add-host=host.docker.internal:host-gateway \
  -v "$ROOT:/liquibase/changelog" \
  -w /liquibase/changelog \
  "$LIQUIBASE_IMAGE" \
  "${ARGS[@]}" \
  update \
  "${LIQUIBASE_CHANGELOG_PARAMS[@]}"
