#!/bin/bash
WINDOW=$(hyprctl activewindow -j 2>/dev/null)
PID=$(echo "$WINDOW" | jq -r '.pid // empty' 2>/dev/null)
CLASS=$(echo "$WINDOW" | jq -r '.class // empty' 2>/dev/null)

if [[ -z "$PID" ]]; then
  hyprctl dispatch killactive
  exit 0
fi

TERMINALS="foot kitty alacritty wezterm ghostty"

kill_tree() {
  local pid=$1
  for child in $(pgrep -P "$pid" 2>/dev/null); do
    kill_tree "$child"
  done
  kill "$pid" 2>/dev/null
}

if echo "$TERMINALS" | grep -qiw "$CLASS"; then
  kill_tree "$PID"
fi

hyprctl dispatch killactive
