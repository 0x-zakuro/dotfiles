#!/bin/bash

# 1. Close the panel INSTANTLY so it doesn't block the screen
swaync-client -t

# 2. Wait for the slide-out animation to finish (0.5s is safe)
sleep 0.5

# 3. Save current shader state so we can restore it later
OLD_SHADER=$(hyprctl getoption decoration:screen_shader -j | jq -r .str)

# 4. Kill the shader so we pick the TRUE color (not the yellowish tint)
hyprctl keyword decoration:screen_shader ""

# 5. Pick the color and copy to clipboard
# If successful, it sends a notification
if COLOR=$(hyprpicker -a); then
    notify-send -a "Color Picker" "󰈊 Color Picked" "$COLOR copied to clipboard"
fi

# 6. RESTORE the shader state (even if you cancelled the picker)
if [[ "$OLD_SHADER" != "None" ]]; then
    hyprctl keyword decoration:screen_shader "$OLD_SHADER"
fi