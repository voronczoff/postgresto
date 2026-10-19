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

TIMESTAMP=$(date +"%Y%m%dT%H%M%S")
BACKUP_FILE="/tmp/${PGDATABASE}_postgresto_${TIMESTAMP}.bak"

pg_dump \
  --dbname="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}" \
  --schema=postgresto \
  --format=custom \
  --compress=zstd \
  -T 'postgresto.search' \
  -T 'postgresto.*_history' \
  -T 'postgresto.*_events' \
  -T 'postgresto.*_raw' \
  --file="$BACKUP_FILE"

echo "Backup of postgresto schema completed: $BACKUP_FILE"
