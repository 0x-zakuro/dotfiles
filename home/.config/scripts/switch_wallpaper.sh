#!/bin/bash

# 1. Path to your wallpapers folder (Change this to your actual folder!)
WALLPAPER_DIR="/home/kuro/.config/wallpaper/home_wallpapers/"

# 2. File to store the current index (keeps track of where you are)
STATE_FILE="/tmp/wallpaper_index"

# 3. Get a sorted list of all images in the folder
# We use an array so we can grab them by number
wallpapers=($(ls "$WALLPAPER_DIR" | grep -E ".jpg$|.png$|.jpeg$|.webp$"))
total_walls=${#wallpapers[@]}

# 4. If state file doesn't exist, start at 0
if [ ! -f "$STATE_FILE" ]; then
  echo 0 >"$STATE_FILE"
fi

# 5. Read current index
current_index=$(cat "$STATE_FILE")

# 6. Safety check: if index is somehow higher than total walls (e.g. you deleted a file)
if [ "$current_index" -ge "$total_walls" ]; then
  current_index=0
fi

# 7. Apply the wallpaper
# NOTE: I'm assuming you use 'swww'. Change 'swww img' to 'hyprpaper' if needed.
awww img "$WALLPAPER_DIR/${wallpapers[$current_index]}" --transition-type fade --transition-duration 8 --transition-fps 60

# 8. Calculate next index and loop back to 0 if at the end
next_index=$(((current_index + 1) % total_walls))

# 9. Save next index for the next click
echo "$next_index" >"$STATE_FILE"
