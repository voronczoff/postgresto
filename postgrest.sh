#!/usr/bin/env bash
# Run PostgREST using Postgres settings from repo-root .env (no postgrest.cfg).
#
# JWT auth ON/OFF (see .env.example and docs/postgrest.md):
#   Default db-anon-role is postgres (not the limited `anon` role).
#   ON:  set PGRST_JWT_SECRET (quoted JWKS); JWT claim role=authenticated still applies
#   OFF: unset PGRST_JWT_SECRET; PGRST_DB_ANON_ROLE defaults to PGUSER (postgres)
set -euo pipefail
cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi


export PGRST_ADMIN_SERVER_PORT=3001

PGHOST=${PGHOST:-localhost}
PGPORT=${PGPORT:-5432}
PGUSER=${PGUSER:-postgres}
PGPASSWORD=${PGPASSWORD:-postgres}
PGDATABASE=${PGDATABASE:-postgresto-local}
PGSCHEMAS=${PGSCHEMAS:?PGSCHEMAS is required}

export PGRST_DB_URI="${PGRST_DB_URI:-postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}}"

# PostgREST uses the first exposed schema when no profile header is provided.
# Keep the framework schema exposed, but make the first application schema the
# default even when older .env files still list postgresto first.
_app_schemas=
IFS=',' read -r -a _configured_schemas <<< "$PGSCHEMAS"
for _schema in "${_configured_schemas[@]}"; do
  _schema="${_schema#"${_schema%%[![:space:]]*}"}"
  _schema="${_schema%"${_schema##*[![:space:]]}"}"
  if [ -n "$_schema" ] && [ "$_schema" != "postgresto" ]; then
    _app_schemas="${_app_schemas:+$_app_schemas,}$_schema"
  fi
done
export PGRST_DB_SCHEMAS="${PGRST_DB_SCHEMAS:-${_app_schemas:+$_app_schemas,}postgresto}"
# Default anon role is postgres (lab). Override with PGRST_DB_ANON_ROLE=anon for locked-down no-JWT.
if [ -n "${PGRST_JWT_SECRET:-}" ]; then
  export PGRST_DB_ANON_ROLE="${PGRST_DB_ANON_ROLE:-${PGUSER}}"
  export PGRST_JWT_SECRET
  export PGRST_JWT_ROLE_CLAIM_KEY="${PGRST_JWT_ROLE_CLAIM_KEY:-$.role}"
else
  export PGRST_DB_ANON_ROLE="${PGRST_DB_ANON_ROLE:-${PGUSER}}"
fi
export PGRST_DB_AGGREGATES_ENABLED="${PGRST_DB_AGGREGATES_ENABLED:-1}"

# Listen port: PGRST_SERVER_PORT, else port from POSTGREST_API_BASE, else 3000
if [ -z "${PGRST_SERVER_PORT:-}" ] && [ -n "${POSTGREST_API_BASE:-}" ]; then
  _port="${POSTGREST_API_BASE##*:}"
  _port="${_port%%/*}"
  case "$_port" in
    ''|*[!0-9]*) ;;
    *) PGRST_SERVER_PORT="$_port" ;;
  esac
fi
export PGRST_SERVER_PORT="${PGRST_SERVER_PORT:-3000}"

exec postgrest
