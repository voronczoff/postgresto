# initialize base settings
if [ -f "init.sh" ]; then
  # If the file exists, run it
  source init.sh
fi

#!/bin/bash
set -x #echo on

# cd to location of script file
cd "$(dirname "$0")"

# Check if STACK_ID is empty and set it to "common" if it is
STACK_ID=${STACK_ID:-common}

# update base image
docker compose  --profile ${STACK_ID} pull

docker compose  --profile ${STACK_ID} down

docker compose --profile ${STACK_ID} up --force-recreate --build -d

echo $(date -u +"%Y-%m-%dT%H:%M:%SZ")