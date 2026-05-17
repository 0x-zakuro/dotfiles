#!/bin/bash

# 1. Grab current shader path (Sanitize for Hyprland internal strings)
# Hyprland returns "[[Empty]]" or "None" if unset
RAW_VAL=$(hyprctl getoption decoration:screen_shader -j | jq -r '.str')

if [[ "$RAW_VAL" == "[[Empty]]" || "$RAW_VAL" == "None" || "$RAW_VAL" == "(unset)" || -z "$RAW_VAL" ]]; then
    OLD_SHADER=""
else
    OLD_SHADER="$RAW_VAL"
fi

# 2. Disable shader if one was active
if [[ -n "$OLD_SHADER" ]]; then
    hyprctl keyword decoration:screen_shader ""
    # Crucial 0.1s sleep so the GPU can clear the nightlight before the snap
    sleep 0.1 
fi

# 3. Setup Variables (Using $HOME is safer than ~)
DATE=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"

# 4. Perform Screenshot based on argument
case $1 in
    "area-clipboard")
        GEOM=$(slurp)
        if [ -n "$GEOM" ]; then
            grim -g "$GEOM" - | wl-copy && notify-send -a "Screenshot" "Copied" "Region copied to clipboard"
        fi
        ;;
    "full-file")
        mkdir -p "$SCREENSHOT_DIR"
        grim "$SCREENSHOT_DIR/Screenshot_$DATE.png" && notify-send -a "Screenshot" "Saved" "Full screen saved to $SCREENSHOT_DIR"
        ;;
    "area-file")
        mkdir -p "$SCREENSHOT_DIR"
        GEOM=$(slurp)
        if [ -n "$GEOM" ]; then
            grim -g "$GEOM" "$SCREENSHOT_DIR/Screenshot_$DATE.png" && notify-send -a "Screenshot" "Saved" "Region saved to $SCREENSHOT_DIR"
        fi
        ;;
esac

# 5. RESTORE the shader if we turned one off
if [[ -n "$OLD_SHADER" ]]; then
    hyprctl keyword decoration:screen_shader "$OLD_SHADER"
fi