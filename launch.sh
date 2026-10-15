#!/usr/bin/env bash
# launch.sh — kill leftovers, Liquibase, PostgREST, Vite

set -euo pipefail

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

SEED_DB=${SEED_DB:-1}

# 1. Kill without checking
pkill -9 -x postgrest 2>/dev/null || true
pkill -9 -f "[n]ode.*vite|[v]ite" 2>/dev/null || true

# 2. Liquibase
if [ "$SEED_DB" = "1" ] && command -v psql >/dev/null 2>&1; then
  echo "Applying Liquibase..."
  (cd scripts && ./applyLiquibase.sh) || {
    echo "Warning: Liquibase apply failed; UI requires framework tables via PostgREST." >&2
  }
fi

# 3. PostgREST
echo "Starting postgrest..."
nohup ./postgrest.sh >postgrest.log 2>&1 &
echo "postgrest started (pid $!), log → postgrest.log"

# 4. Vite
if [ ! -d node_modules ]; then
  echo "Installing dependencies..."
  npm install
fi
echo "Starting Vite..."
npm run dev
