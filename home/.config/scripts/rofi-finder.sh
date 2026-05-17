#!/usr/bin/env bash

# Define your base directory once to keep it DRY
BASE_DIR="/home/kuro"

if [ -z "$@" ]; then
  # List files for Rofi to display
  fd --type f --hidden --exclude .git --base-directory "$BASE_DIR"
else
  foot -e nvim "$BASE_DIR/$@" >/dev/null 2>&1 &

  # Exit the script so Rofi closes immediately
  exit
fi
