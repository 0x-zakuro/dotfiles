#!/usr/bin/env bash
BASE_DIR="$HOME"
if [ -z "$@" ]; then
  fd --type f --hidden --exclude .git --base-directory "$BASE_DIR"
else
  foot -e nvim "$BASE_DIR/$@" >/dev/null 2>&1 &
  exit
fi
