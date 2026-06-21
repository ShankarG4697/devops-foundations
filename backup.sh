#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Piece 1: Validate input
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

SOURCE_DIR="$1"

# Piece 2: Check the folder exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Directory '$SOURCE_DIR' does not exist."
  exit 1
fi

# Piece 3: Build timestamp and output filename
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
FOLDER_NAME=$(basename "$SOURCE_DIR")
ARCHIVE_NAME="${FOLDER_NAME}_${TIMESTAMP}.tar.gz"

# Piece 4: Make sure backups/ exists, then create the archive
mkdir -p "$SCRIPT_DIR/backups"
tar -czf "$SCRIPT_DIR/backups/$ARCHIVE_NAME" "$SOURCE_DIR"
TAR_EXIT=$?

# Piece 5: Check if tar succeeded and log it
if [ $TAR_EXIT -eq 0 ]; then
  SIZE=$(du -h "$SCRIPT_DIR/backups/$ARCHIVE_NAME" | cut -f1)
  echo "$TIMESTAMP | SUCCESS | source: $SOURCE_DIR | archive: $ARCHIVE_NAME | size: $SIZE" >> "$SCRIPT_DIR/backup.log"
else
  echo "$TIMESTAMP | FAILURE | source: $SOURCE_DIR | archive: $ARCHIVE_NAME" >> "$SCRIPT_DIR/backup.log"
fi
