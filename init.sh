echo $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read environment variables from .env file
if [ -f ./.env ]; then
  source ./.env
fi

#!/bin/bash
set -x #echo on

# exit on error
set -o errexit

# cd to location of script file
cd "$(dirname "$0")"

# set root:docker permissions
# sh ./setPermissions.sh
