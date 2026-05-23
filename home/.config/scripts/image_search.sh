#!/usr/bin/env bash
# Captures a screen region (CLEAN - no shader) and searches with Google Lens.

# --- [ CONFIGURATION ] --------------------------------------------------------
readonly USE_UPLOAD_SERVICE="true"

# --- [ STRICT MODE ] ----------------------------------------------------------
set -euo pipefail

# --- [ DEPENDENCY CHECK ] -----------------------------------------------------
command -v hyprctl >/dev/null 2>&1 || {
  echo "hyprctl not found"
  exit 1
}
command -v grim >/dev/null 2>&1 || {
  echo "grim not found"
  exit 1
}
command -v slurp >/dev/null 2>&1 || {
  echo "slurp not found"
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  echo "jq not found"
  exit 1
}

# --- [ HELPER FUNCTIONS ] -----------------------------------------------------

notify() {
  notify-send -a "Google Lens" "$1" "$2" 2>/dev/null || true
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
# jq -r outputs empty string "" for null, not "None"
OLD_SHADER=$(hyprctl getoption decoration:screen_shader -j 2>/dev/null | jq -r '.str // empty') || OLD_SHADER=""

# 2. DISABLE SHADER FOR CLEAN CAPTURE
hyprctl keyword decoration:screen_shader "" 2>/dev/null || true

printf '📷 Select region...\n'

# 3. Capture Geometry
if ! geometry=$(slurp 2>/dev/null); then
  printf '🚫 Selection cancelled.\n'
  # Restore shader if it was set
  [[ -n "$OLD_SHADER" ]] && hyprctl keyword decoration:screen_shader "$OLD_SHADER" 2>/dev/null || true
  exit 0
fi

# 4. CAPTURE THE IMAGE
tmp_file=$(mktemp /tmp/lens-XXXXXX.png)
trap 'rm -f "${tmp_file}"' EXIT

grim -g "${geometry}" "${tmp_file}" || die "grim failed to capture screenshot"

# 5. RESTORE SHADER IMMEDIATELY
[[ -n "$OLD_SHADER" ]] && hyprctl keyword decoration:screen_shader "$OLD_SHADER" 2>/dev/null || true

# --- [ PROCESSING ] -----------------------------------------------------------

if [[ "${USE_UPLOAD_SERVICE}" == "true" ]]; then
  notify "Uploading..." "Sending clean image to Google Lens"

  if ! response=$(curl -sSf -F "files[]=@${tmp_file}" 'https://uguu.se/upload' 2>/dev/null); then
    die "Upload connection failed."
  fi

  url=$(jq -r '.files[0].url // empty' <<<"${response}")
  [[ -z "${url}" ]] && die "Upload succeeded but URL parsing failed."

  open_url "https://lens.google.com/uploadbyurl?url=${url}"
else
  # CLIPBOARD MODE
  wl-copy <"${tmp_file}" || die "wl-copy failed"
  notify "Ready" "Clean screenshot copied. Paste in browser."
  open_url "https://lens.google.com/"
fi

