#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$ROOT/.env"
  set +a
fi

PGHOST=${PGHOST:-localhost}
PGPORT=${PGPORT:-5432}
PGUSER=${PGUSER:-postgres}
PGPASSWORD=${PGPASSWORD:-postgres}
PGDATABASE=${PGDATABASE:-postgresto-local}
SEARCH_TABLE=${VITE_SEARCH_TABLE:-search}

BACKUP_DIR="${HOME}/backup/postgresto"
TIMESTAMP=$(date +"%Y%m%dT%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${PGDATABASE}_postgresto_${TIMESTAMP}.bak"

mkdir -p "$BACKUP_DIR"

pg_dump \
  --dbname="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}" \
  --schema=postgresto \
  --format=custom \
  --compress=zstd \
  -T "postgresto.${SEARCH_TABLE}" \
  -T 'postgresto.*_history' \
  -T 'postgresto.*_events' \
  -T 'postgresto.*_raw' \
  --file="$BACKUP_FILE"

echo "Backup of postgresto schema completed: $BACKUP_FILE"
