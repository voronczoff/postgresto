#!/bin/sh

# Define the directory to be archived
DIR="./volumes"

# Define the backup directory
BACKUP_DIR="/opt/archDB/volumes"

# Create the backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Get the current date and time
DATE=$(date +"%Y%m%d_%H%M%S")

# Get the Docker Compose project name
PROJECT_NAME=$(basename "$PWD")




# Define the archive filename
ARCHIVE_FILE="$BACKUP_DIR/${PROJECT_NAME}_volumes_backup_$DATE.7z"

# Archive the directory using 7z
7z a $ARCHIVE_FILE $DIR

# Print a message indicating the backup is complete
echo "Backup of $DIR completed and saved as $ARCHIVE_FILE"
