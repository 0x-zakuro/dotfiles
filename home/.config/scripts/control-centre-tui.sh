#!/bin/bash
# ~/.config/scripts/control-centre-tui.sh
# Ultimate Premium Control Center - Flawless UI & Brightness Controls

# ──── Setup ────
hide_cursor() { printf "\e[?25l"; }
show_cursor() { printf "\e[?25h"; }
alt_screen() { printf "\e[?1049h"; }
main_screen() { printf "\e[?1049l"; }
clear_screen() { printf "\e[2J\e[H"; }

cleanup() {
  stty echo
  show_cursor
  main_screen
  exit 0
}
trap cleanup INT TERM EXIT

# Disable terminal echoing so arrow keys don't bleed onto the screen while loading
stty -echo

# ──── ANSI Colors ────
PINK="\e[38;5;212m"
PURPLE="\e[38;5;99m"
GREEN="\e[38;5;82m"
RED="\e[38;5;203m"
YELLOW="\e[38;5;214m"
GRAY="\e[38;5;240m"
LIGHT="\e[38;5;252m"
RESET="\e[0m"
BOLD="\e[1m"
BG_GREEN="\e[48;5;82m\e[30m"
BG_RED="\e[48;5;203m\e[30m"
BG_YELLOW="\e[48;5;214m\e[30m"
BG_PURPLE="\e[48;5;99m\e[30m"

# ──── State Files ────
NL_FILE="$HOME/.cache/tui-nl-state"
[ -f "$NL_FILE" ] || echo "0" >"$NL_FILE"

CAFFEINE_FILE="$HOME/.cache/tui-caffeine-state"
[ -f "$CAFFEINE_FILE" ] || echo "off" >"$CAFFEINE_FILE"

# ──── State Helpers ────
wifi_state() { nmcli -t radio wifi 2>/dev/null | grep -q enabled && echo "ON" || echo "off"; }
bt_state() { rfkill -o TYPE,SOFT -n 2>/dev/null | grep bluetooth | grep -q unblocked && echo "ON" || echo "off"; }
vol_state() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED && echo "MUTED" || echo "ON"; }
mic_state() { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED && echo "MUTED" || echo "ON"; }
vol_pct() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}'; }
mic_pct() { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print int($2*100)}'; }
bright_pct() {
  local c m
  c=$(brightnessctl g 2>/dev/null)
  m=$(brightnessctl m 2>/dev/null)
  [ -n "$m" ] && [ "$m" -ne 0 ] && echo $(((c * 100 + m / 2) / m)) || echo "0"
}

# Night Light (3-state)
nl_state() { cat "$NL_FILE" 2>/dev/null || echo "0"; }
nl_label() {
  case "$(nl_state)" in
  0) echo "off" ;;
  1) echo "mild" ;;
  2) echo "aggressive" ;;
  *) echo "off" ;;
  esac
}

# Caffeine (Binary)
caffeine_state() { cat "$CAFFEINE_FILE" 2>/dev/null || echo "off"; }

# ──── Actions ────
toggle_wifi() {
  if [ "$(wifi_state)" = "ON" ]; then
    nmcli radio wifi off
  else
    nmcli radio wifi on
  fi
}
toggle_bt() {
  if [ "$(bt_state)" = "ON" ]; then
    rfkill block bluetooth
  else
    rfkill unblock bluetooth
  fi
}
toggle_vol() { wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; }
toggle_mic() { wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; }
adj_vol() { wpctl set-volume @DEFAULT_AUDIO_SINK@ "${1}%${2}"; }
adj_mic() { wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${1}%${2}"; }

adj_bright() {
  if [ "$1" = "+" ]; then
    brightnessctl set +5% >/dev/null 2>&1
  else
    brightnessctl set 5%- >/dev/null 2>&1
  fi
}

cycle_nl() {
  local s=$(($(nl_state) + 1))
  [ "$s" -gt 2 ] && s=0
  echo "$s" >"$NL_FILE"
  case "$s" in
  0) hyprctl keyword decoration:screen_shader "" 2>/dev/null || true ;;
  1) ~/.config/scripts/nightlight.sh mild 2>/dev/null || true ;;
  2) ~/.config/scripts/nightlight.sh aggressive 2>/dev/null || true ;;
  esac
}

toggle_caffeine() {
  local current=$(caffeine_state)
  if [[ "${current^^}" == "ON" || "$current" == "1" ]]; then
    echo "off" >"$CAFFEINE_FILE"
    ~/.config/scripts/caffeine_mode.sh off 2>/dev/null || true
  else
    echo "ON" >"$CAFFEINE_FILE"
    ~/.config/scripts/caffeine_mode.sh on 2>/dev/null || true
  fi
}

zoom_out() {
  local mon scale
  mon=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name')
  scale=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .scale - 0.2')
  [ -n "$mon" ] && hyprctl keyword monitor "${mon},preferred,auto,${scale}"
}
zoom_in() {
  local mon scale
  mon=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name')
  scale=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .scale + 0.2')
  [ -n "$mon" ] && hyprctl keyword monitor "${mon},preferred,auto,${scale}"
}

# ──── Badge Renderer ────
badge() {
  case "${1^^}" in
  ON | 1) printf "%b" "${BG_GREEN}  ON    ${RESET}" ;;
  OFF | 0) printf "%b" "${BG_RED}  OFF   ${RESET}" ;;
  MILD) printf "%b" "${BG_YELLOW}  MILD  ${RESET}" ;;
  AGGRESSIVE) printf "%b" "${BG_PURPLE}  AGGR  ${RESET}" ;;
  MUTED) printf "%b" "${BG_YELLOW}  MUTED ${RESET}" ;;
  *) printf "%b" "${GRAY}  %-6s${RESET}" "${1^^}" ;;
  esac
}

# ──── Menu Definition ────
render_menu() {
  local w=$(wifi_state)
  local b=$(bt_state)
  local v=$(vol_state)
  local vp=$(vol_pct)
  local m=$(mic_state)
  local mp=$(mic_pct)
  local br=$(bright_pct)
  local n=$(nl_label)
  local c=$(caffeine_state)

  local vp_pad=$(printf "%-3s" "$vp")
  local mp_pad=$(printf "%-3s" "$mp")
  local br_pad=$(printf "%-3s" "$br")

  local out=""
  out+="\e[H"

  out+="\n  ${PURPLE}${BOLD}        󱂬  Control Center${RESET}\e[K\n\n"

  out+="  ${GRAY}┄┄┄ Network ┄┄┄${RESET}\e[K\n"
  [ "$sel" -eq 0 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰤨  WiFi\e[34G${RESET}$(badge "$w")\e[K\n"

  [ "$sel" -eq 1 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰂯  Bluetooth\e[34G${RESET}$(badge "$b")\e[K\n"

  out+="\n  ${GRAY}┄┄┄ Media ┄┄┄${RESET}\e[K\n"
  [ "$sel" -eq 2 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰕾  Volume ${vp_pad}%\e[34G${RESET}$(badge "$v")\e[K\n"

  [ "$sel" -eq 3 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰍬  Mic ${mp_pad}%\e[34G${RESET}$(badge "$m")\e[K\n"

  [ "$sel" -eq 4 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰃠  Brightness ${br_pad}%\e[K\n"

  out+="\n  ${GRAY}┄┄┄ Environment ┄┄┄${RESET}\e[K\n"
  [ "$sel" -eq 5 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰖨  Night Light\e[34G${RESET}$(badge "$n")\e[K\n"

  [ "$sel" -eq 6 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰒳  Caffeine\e[34G${RESET}$(badge "$c")\e[K\n"

  out+="\n  ${GRAY}┄┄┄ Tools ┄┄┄${RESET}\e[K\n"
  [ "$sel" -eq 7 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}  Change Wallpaper${RESET}\e[K\n"
  [ "$sel" -eq 8 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰈊  Color Picker${RESET}\e[K\n"
  [ "$sel" -eq 9 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰎚  Open Obsidian${RESET}\e[K\n"
  [ "$sel" -eq 10 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰥷  Image Search${RESET}\e[K\n"

  out+="\n  ${GRAY}┄┄┄ System ┄┄┄${RESET}\e[K\n"
  [ "$sel" -eq 11 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}󰍹  Monitor Scaling${RESET}\e[K\n"
  [ "$sel" -eq 12 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}⏻  Power Menu${RESET}\e[K\n"

  out+="\n"
  [ "$sel" -eq 13 ] && out+="${PINK}❯ ${RESET}" || out+="  "
  out+="${LIGHT}❌  Exit${RESET}\e[K\n"

  out+="\n  ${GRAY}↑↓ navigate · ←→ adjust · Enter toggle · q quit${RESET}\e[K\n"

  out+="\e[J"

  printf "%b" "$out"
}

# ──── Key Reading ────
read_key() {
  local key
  if IFS= read -rs -t 0.1 -n 1 key 2>/dev/null; then
    if [[ "$key" == $'\e' ]]; then
      if IFS= read -rs -t 0.05 -n 2 key 2>/dev/null; then
        case "$key" in
        '[A') echo "UP" ;;
        '[B') echo "DOWN" ;;
        '[C') echo "RIGHT" ;;
        '[D') echo "LEFT" ;;
        *) echo "OTHER" ;;
        esac
      fi
    elif [[ -z "$key" || "$key" == $'\n' || "$key" == $'\r' ]]; then
      echo "ENTER"
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
      echo "QUIT"
    else
      echo "OTHER"
    fi
  fi
}

# ──── Main ────
main() {
  alt_screen
  hide_cursor
  clear_screen
  local sel=0
  local max=13

  while true; do
    render_menu

    local key
    key=$(read_key)

    case "$key" in
    UP)
      sel=$((sel - 1))
      [ "$sel" -lt 0 ] && sel=$max
      ;;
    DOWN)
      sel=$((sel + 1))
      [ "$sel" -gt "$max" ] && sel=0
      ;;
    LEFT)
      case "$sel" in
      2) adj_vol 5 - ;;
      3) adj_mic 5 - ;;
      4) adj_bright - ;; # Lower brightness
      esac
      ;;
    RIGHT)
      case "$sel" in
      2) adj_vol 5 + ;;
      3) adj_mic 5 + ;;
      4) adj_bright + ;; # Raise brightness
      esac
      ;;
    ENTER)
      case "$sel" in
      0)
        toggle_wifi
        sleep 0.2
        ;;
      1)
        toggle_bt
        sleep 0.2
        ;;
      2) toggle_vol ;;
      3) toggle_mic ;;
      4) ;;
      5) cycle_nl ;;
      6) toggle_caffeine ;;
      7) ~/.config/scripts/switch_wallpaper.sh 2>/dev/null || true ;;
      8) ~/.config/scripts/color_picker.sh 2>/dev/null || true ;;
      9) hyprctl dispatch exec '[float; size 1200 800; center] obsidian' ;;
      10) ~/.config/scripts/image_search.sh 2>/dev/null || true ;;
      11)
        clear_screen
        printf "\n  ${PURPLE}󰍹  Monitor Scaling${RESET}\n\n"
        printf "  ${LIGHT}  Scale Up (+0.2)${RESET}\n"
        printf "  ${LIGHT}  Scale Down (-0.2)${RESET}\n\n"
        printf "  ${GRAY}Press 1 for Up, 2 for Down, any other key to cancel${RESET}\n"
        local skey
        skey=$(read_key)
        case "$skey" in
        "UP") zoom_in ;;
        "DOWN") zoom_out ;;
        esac
        clear_screen
        ;;
      12)
        clear_screen
        printf "\n  ${RED}⏻  Power Menu${RESET}\n\n"
        printf "  ${LIGHT}󰍃  Logout${RESET}\n"
        printf "  ${LIGHT}󰌾  Lock Screen${RESET}\n"
        printf "  ${LIGHT}  Reboot${RESET}\n"
        printf "  ${LIGHT}󰒓  Reboot to BIOS${RESET}\n"
        printf "  ${LIGHT}  Arch Reboot${RESET}\n"
        printf "  ${LIGHT}⏻  Shutdown${RESET}\n\n"
        printf "  ${GRAY}Press 1-6 to select, any other key to cancel${RESET}\n"
        local pkey
        pkey=$(read_key)
        case "$pkey" in
        "OTHER" | "UP" | "DOWN") ;;
        "ENTER")
          printf "  ${RED}Confirm? (y/n) ${RESET}"
          local confirm
          read -n1 -r confirm
          printf "\n"
          ;;
        esac
        clear_screen
        ;;
      13) cleanup ;;
      esac
      ;;
    QUIT)
      cleanup
      ;;
    esac
  done
}

main
