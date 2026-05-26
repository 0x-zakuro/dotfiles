#!/bin/bash

# Check if hypridle is running
if pgrep -x "hypridle" >/dev/null; then
  # If running, kill it to prevent screen sleep (CAFFEINE ON)
  pkill hypridle
else
  # If not running, tell Hyprland to start it back up (CAFFEINE OFF)
  hyprctl dispatch exec hypridle
fi
