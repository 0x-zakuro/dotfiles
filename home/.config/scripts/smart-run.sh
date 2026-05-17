#!/usr/bin/env bash

# Get just the app name (e.g., "obsidian" instead of "/usr/bin/obsidian")
APP_NAME=$(basename "$1")

GUI_APPS="obsidian firefox discord spotify code"

if [[ $GUI_APPS =~ (^|[[:space:]])"$APP_NAME"($|[[:space:]]) ]]; then
  # Run GUI apps in background
  "$@" >/dev/null 2>&1 &
else
  # Run CLI tools in the terminal
  foot -e "$@"
fi
