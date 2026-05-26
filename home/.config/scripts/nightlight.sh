#!/bin/bash

# Get the current shader state from Hyprland
STATE=$(hyprctl getoption decoration:screen_shader)

# Check which mode is currently running
if echo "$STATE" | grep -q "nightlight_mild.frag"; then
  # Currently Mild -> Switch to Aggressive
  hyprctl keyword decoration:screen_shader "/home/kuro/.config/scripts/nightlight_aggressive.frag"

elif echo "$STATE" | grep -q "nightlight_aggressive.frag"; then
  # Currently Aggressive -> Turn Off completely
  hyprctl keyword decoration:screen_shader ""

else
  # Currently Off -> Turn on Mild
  hyprctl keyword decoration:screen_shader "/home/kuro/.config/scripts/nightlight_mild.frag"
fi

