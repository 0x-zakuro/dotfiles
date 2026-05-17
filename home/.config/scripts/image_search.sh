#!/usr/bin/env bash
# Captures a screen region (CLEAN - no shader) and searches with Google Lens.

# --- [ CONFIGURATION ] --------------------------------------------------------
readonly USE_UPLOAD_SERVICE="true"

# --- [ STRICT MODE ] ----------------------------------------------------------
set -euo pipefail

# --- [ HELPER FUNCTIONS ] -----------------------------------------------------

# This is the function that was missing!
notify() {
    notify-send -a "Google Lens" "$1" "$2"
}

open_url() {
    xdg-open "$1" &
    disown
}

die() {
    printf '❌ %s\n' "$1" >&2
    notify "Error" "$1"
    exit 1
}

# --- [ MAIN LOGIC ] -----------------------------------------------------------

# 1. SAVE SHADER STATE
# We grab the current shader path so we can restore it later
OLD_SHADER=$(hyprctl getoption decoration:screen_shader -j | jq -r .str)

# 2. DISABLE SHADER FOR CLEAN CAPTURE
# We want Google Lens to see the original image, not your 2700K tint
hyprctl keyword decoration:screen_shader ""

printf '📷 Select region...\n'

# 3. Capture Geometry
if ! geometry=$(slurp 2>/dev/null); then
    printf '🚫 Selection cancelled.\n'
    # Restore shader if cancelled
    [[ "$OLD_SHADER" != "None" ]] && hyprctl keyword decoration:screen_shader "$OLD_SHADER"
    exit 0
fi

# 4. CAPTURE THE IMAGE
tmp_file=$(mktemp /tmp/lens-XXXXXX.png)
trap 'rm -f "${tmp_file}"' EXIT

grim -g "${geometry}" "${tmp_file}"

# 5. RESTORE SHADER IMMEDIATELY
# We don't wait for the upload; we protect your eyes right away
if [[ "$OLD_SHADER" != "None" ]]; then
    hyprctl keyword decoration:screen_shader "$OLD_SHADER"
fi

# --- [ PROCESSING ] -----------------------------------------------------------

if [[ "${USE_UPLOAD_SERVICE}" == "true" ]]; then
    notify "Uploading..." "Sending clean image to Google Lens"

    if ! response=$(curl -sSf -F "files[]=@${tmp_file}" 'https://uguu.se/upload'); then
        die "Upload connection failed."
    fi

    url=$(jq -r '.files[0].url // empty' <<< "${response}")
    [[ -z "${url}" ]] && die "Upload succeeded but URL parsing failed."

    open_url "https://lens.google.com/uploadbyurl?url=${url}"
else
    # CLIPBOARD MODE
    cat "${tmp_file}" | wl-copy
    notify "Ready" "Clean screenshot copied. Paste in browser."
    open_url "https://lens.google.com/"
fi