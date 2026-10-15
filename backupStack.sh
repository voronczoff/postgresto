#!/bin/bash

# Initialize base settings
if [ -f "init.sh" ]; then
  # If the file exists, run it
  source init.sh
fi

set -x # Echo on

# Get the current directory name
current_dir=$(basename "$PWD")

# Get the current timestamp
timestamp=$(date +"%Y%m%dT%H%M%S")

# Move to the parent directory
cd ..

# Create a 7z archive of the current directory with the timestamp with the lowest priority
nice -n 19 7z a "${current_dir}_${timestamp}.7z" "$current_dir"
