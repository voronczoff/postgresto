#!/bin/bash
set -euo pipefail
set -x

# Run from the repository root even when invoked from another directory.
cd "$(dirname "$0")"

# Initialize optional local deployment settings before reading STACK_ID.
if [ -f "init.sh" ]; then
  # shellcheck disable=SC1091
  source init.sh
fi

STACK_ID=${STACK_ID:-common}
SERVICE_NAME=${1:-}

# nginx serves ./dist from the host. Rebuild it when refreshing the full stack
# or proxy itself so Docker cannot keep serving a stale frontend bundle.
#if [ -z "$SERVICE_NAME" ] || [ "$SERVICE_NAME" = "proxy" ]; then
#  npm run build
#fi

if [ -n "$SERVICE_NAME" ]; then
  docker compose --profile "$STACK_ID" down "$SERVICE_NAME"
  docker compose --profile "$STACK_ID" up "$SERVICE_NAME" --force-recreate --build -d
else
  docker compose --profile "$STACK_ID" down
  docker compose --profile "$STACK_ID" up --force-recreate --build -d
fi

date -u +"%Y-%m-%dT%H:%M:%SZ"
