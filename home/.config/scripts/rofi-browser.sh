#!/usr/bin/env bash

# Define where to save the history
HISTORY_FILE="$HOME/.config/rofi/web_history.txt"

# Make sure the history file exists
touch "$HISTORY_FILE"

# 1. NO INPUT YET: Show the history list
if [ -z "$1" ]; then
  # Read the history file, flip it so newest is at the top (tac),
  # remove any duplicates (awk), and show the last 15 searches (head).
  tac "$HISTORY_FILE" | awk '!seen[$0]++' | head -n 15
  exit 0
fi

QUERY="$1"

# 2. SAVE TO HISTORY:
# Save the exact query to the history file so it appears next time
if [ -n "$QUERY" ]; then
  echo "$QUERY" >>"$HISTORY_FILE"
fi

# 3. LAUNCH BROWSER
if [[ "$QUERY" != *" "* ]] && [[ "$QUERY" == *"."* ]]; then
  # URL logic
  if [[ "$QUERY" != http* ]]; then
    QUERY="https://$QUERY"
  fi
  nohup helium-browser "$QUERY" >/dev/null 2>&1 &
  disown
else
  # Google Search logic
  nohup helium-browser "https://www.google.com/search?q=$QUERY" >/dev/null 2>&1 &
  disown
fi

exit 0
