#!/usr/bin/env bash

REMOTE_PATH="$1"
LOCAL_PATH="$2"

if [ -z "$REMOTE_PATH" ] || [ -z "$LOCAL_PATH" ]; then
  exit 1
fi

# Get initial remote modification time
last_time=$(rclone lsf --format "t" "$REMOTE_PATH" 2>/dev/null)

# Run for up to 2 hours (1440 iterations * 5 seconds = 2 hours)
# This loop exits early if the local file is deleted or if no changes occur for 2 hours
for i in $(seq 1 1440); do
  sleep 5

  # Check if remote modification time has changed
  current_time=$(rclone lsf --format "t" "$REMOTE_PATH" 2>/dev/null)
  
  if [ -n "$current_time" ] && [ "$current_time" != "$last_time" ]; then
    # Download the updated file from OneDrive back to local path
    rclone copyto "$REMOTE_PATH" "$LOCAL_PATH" 2>/dev/null
    last_time="$current_time"
  fi
done
