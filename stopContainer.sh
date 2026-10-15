# initialize base settings
if [ -f "init.sh" ]; then
  # If the file exists, run it
  source init.sh
fi

# Get the first parameter as the service name
SERVICE_NAME=$1

#!/bin/bash
set -x #echo on

# cd to location of script file
cd "$(dirname "$0")"

# Check if STACK_ID is empty and set it to "common" if it is
STACK_ID=${STACK_ID:-common}

docker compose --profile ${STACK_ID} stop ${SERVICE_NAME}

echo $(date -u +"%Y-%m-%dT%H:%M:%SZ")