#!/bin/bash
# ~/.config/scripts/control-centre-tui.sh
# Control Centre TUI — Hyprland
# ─────────────────────────────────────────────────────────────────────────────

# ── Terminal Control ──────────────────────────────────────────────────────────
hide_cursor() { printf "\e[?25l"; }
show_cursor() { printf "\e[?25h"; }
alt_screen() { printf "\e[?1049h"; }
main_screen() { printf "\e[?1049l"; }
clear_screen() { printf "\e[2J\e[H"; }

# ── Colour Palette ────────────────────────────────────────────────────────────
R="\e[0m"
B="\e[1m"

PK="\e[38;5;219m" # pink
SG="\e[38;5;114m" # sage green
SY="\e[38;5;214m" # amber / yellow
SO="\e[38;5;208m" # orange
SR="\e[38;5;203m" # red
PU="\e[38;5;141m" # purple
SB="\e[38;5;111m" # sky blue

BL="\e[38;2;51;177;255m" # #33b1ff (Selection Highlight)
VG="\e[38;2;46;204;113m" # Verdant Green (Sliders)

N1="\e[38;5;255m" # White
N2="\e[38;5;252m"
N3="\e[38;5;249m"
N4="\e[38;5;245m"
N5="\e[38;5;241m"
N6="\e[38;5;238m"
N7="\e[38;5;235m"

BGSEL="\e[48;5;237m"

# ── State Files ───────────────────────────────────────────────────────────────
NL_FILE="$HOME/.cache/tui-nl-state"
CA_FILE="$HOME/.cache/tui-caffeine-state"
[[ -f "$NL_FILE" ]] || echo "0" >"$NL_FILE"
[[ -f "$CA_FILE" ]] || echo "off" >"$CA_FILE"

# ── Hardware State ────────────────────────────────────────────────────────────
wifi_state() { nmcli -t radio wifi 2>/dev/null | grep -q enabled && echo "ON" || echo "OFF"; }
bt_state() { rfkill -o TYPE,SOFT -n 2>/dev/null | grep bluetooth | grep -q unblocked && echo "ON" || echo "OFF"; }
vol_state() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED && echo "MUTED" || echo "ON"; }
mic_state() { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED && echo "MUTED" || echo "ON"; }
vol_pct() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}'; }
mic_pct() { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print int($2*100)}'; }
bright_pct() {
  local c m
  c=$(brightnessctl g 2>/dev/null)
  m=$(brightnessctl m 2>/dev/null)
  [[ -n "$m" && "$m" -ne 0 ]] && echo $(((c * 100 + m / 2) / m)) || echo "0"
}
nl_label() {
  case "$(cat "$NL_FILE" 2>/dev/null || echo 0)" in
  0) echo "OFF" ;; 1) echo "MILD" ;; 2) echo "WARM" ;; *) echo "OFF" ;;
  esac
}
caff_state() { cat "$CA_FILE" 2>/dev/null || echo "OFF"; }

# ── Actions ───────────────────────────────────────────────────────────────────
toggle_wifi() { [[ "$(wifi_state)" == "ON" ]] && nmcli radio wifi off || nmcli radio wifi on; }
toggle_bt() { [[ "$(bt_state)" == "ON" ]] && rfkill block bluetooth || rfkill unblock bluetooth; }
toggle_vol() { wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; }
toggle_mic() { wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; }
adj_vol() { wpctl set-volume @DEFAULT_AUDIO_SINK@ "${1}%${2}"; }
adj_mic() { wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${1}%${2}"; }
adj_bright() { [[ "$1" == "+" ]] && brightnessctl set +5% >/dev/null 2>&1 ||
  brightnessctl set 5%- >/dev/null 2>&1; }
cycle_nl() {
  local s=$(($(cat "$NL_FILE") + 1))
  ((s > 2)) && s=0
  echo "$s" >"$NL_FILE"
  case "$s" in
  0) hyprctl keyword decoration:screen_shader "" 2>/dev/null ;;
  1) ~/.config/scripts/nightlight.sh mild 2>/dev/null ;;
  2) ~/.config/scripts/nightlight.sh aggressive 2>/dev/null ;;
  esac
}
toggle_caffeine() {
  local cur
  cur=$(caff_state)
  if [[ "${cur^^}" == "ON" ]]; then
    echo "OFF" >"$CA_FILE"
    ~/.config/scripts/caffeine_mode.sh off 2>/dev/null
  else
    echo "ON" >"$CA_FILE"
    ~/.config/scripts/caffeine_mode.sh on 2>/dev/null
  fi
}
zoom_out() {
  local mon scale
  mon=$(hyprctl monitors -j 2>/dev/null | jq -r '.[]|select(.focused)|.name')
  scale=$(hyprctl monitors -j 2>/dev/null | jq -r '.[]|select(.focused)|.scale - 0.2')
  [[ -n "$mon" ]] && hyprctl keyword monitor "${mon},preferred,auto,${scale}"
}
zoom_in() {
  local mon scale
  mon=$(hyprctl monitors -j 2>/dev/null | jq -r '.[]|select(.focused)|.name')
  scale=$(hyprctl monitors -j 2>/dev/null | jq -r '.[]|select(.focused)|.scale + 0.2')
  [[ -n "$mon" ]] && hyprctl keyword monitor "${mon},preferred,auto,${scale}"
}

# ── UI Primitives ─────────────────────────────────────────────────────────────
bar() {
  local pct=$1 w=${2:-12} f i s=""
  f=$((pct * w / 100))
  s+="${VG}" # Verdant green
  for ((i = 0; i < f; i++)); do s+="█"; done
  s+="${N6}" # Dark gray for unselected part
  for ((i = 0; i < w - f; i++)); do s+="░"; done
  s+="${R}"
  printf "%b" "$s"
}

dot() {
  case "${1^^}" in
  ON) printf "${SG}${B}●${R} ${SG}on${R}" ;;
  OFF) printf "${SR}${B}●${R} ${SR}off${R}" ;;
  MILD) printf "${SY}${B}●${R} ${SY}mild${R}" ;;
  WARM) printf "${SO}${B}●${R} ${SO}warm${R}" ;;
  MUTED) printf "${SY}${B}●${R} ${SY}muted${R}" ;;
  *) printf "${N6}●${R} ${N6}${1,,}${R}" ;;
  esac
}

section() {
  printf "\n  ${PU}${B}%-10s${R}" "$1"
  printf "\e[15G${N6}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${R}\n"
}

draw_header() {
  local color="$1"
  local line1="$2"
  local line2="$3"
  local line3="$4"
  local right_text="${5:-}"

  if [[ -z "$right_text" && "$line3" =~ ^[0-9]{1,2}:[0-9]{2} ]]; then
    right_text="$line3"
    line3=""
  fi

  printf "\n"
  printf "  ${color}${B}%s${R}\n" "$line1"
  printf "  ${color}${B}%s${R}\n" "$line2"

  if [[ -n "$line3" ]]; then
    if [[ -n "$right_text" ]]; then
      local pad=$((72 - ${#line3} - ${#right_text}))
      ((pad < 1)) && pad=1
      printf "  ${color}${B}%s${R}%*s${N4}%s${R}\n" "$line3" "$pad" "" "$right_text"
    else
      printf "  ${color}${B}%s${R}\n" "$line3"
    fi
  elif [[ -n "$right_text" ]]; then
    local pad=$((72 - ${#right_text}))
    printf "  %*s${N4}%s${R}\n" "$pad" "" "$right_text"
  fi
  printf "\n"
}

read_key() {
  local key seq
  IFS= read -rs -t 1 -n 1 key || return
  if [[ "$key" == $'\e' ]]; then
    IFS= read -rs -t 0.15 -n 2 seq 2>/dev/null
    case "$seq" in
    '[A') echo "UP" ;; '[B') echo "DOWN" ;;
    '[C') echo "RIGHT" ;; '[D') echo "LEFT" ;;
    *) echo "ESC" ;;
    esac
  elif [[ -z "$key" || "$key" == $'\n' || "$key" == $'\r' ]]; then
    echo "ENTER"
  elif [[ "$key" == [qQ] ]]; then
    echo "QUIT"
  else
    echo "OTHER"
  fi
}

# ── Main Menu State Cache ─────────────────────────────────────────────────────
C_WIFI="" C_BT="" C_VOL="" C_MIC="" C_VOLP="" C_MICP="" C_BR="" C_NL="" C_CA=""

refresh_state() {
  C_WIFI=$(wifi_state)
  C_BT=$(bt_state)
  C_VOL=$(vol_state)
  C_MIC=$(mic_state)
  C_VOLP=$(vol_pct)
  C_MICP=$(mic_pct)
  C_BR=$(bright_pct)
  C_NL=$(nl_label)
  C_CA=$(caff_state)
}

# ── Main Menu Row ─────────────────────────────────────────────────────────────
HL_WIDTH=20
SEL=0

_row() {
  local idx=$1 icon=$2 label=$3 state=${4:-} pct=${5:-}

  if ((SEL == idx)); then
    printf "  ${BL}${B}▍${R}${BGSEL}${BL}${B} %s  %s" "$icon" "$label"
    local pad=$((HL_WIDTH - ${#label}))
    ((pad > 0)) && printf "%*s" "$pad" ""
    printf "${R}"
  else
    printf "    ${N1}%s${R}  ${N2}%-${HL_WIDTH}s${R}" "$icon" "$label"
  fi

  [[ -n "$state" ]] && printf "\e[38G%b" "$(dot "$state")"
  [[ -n "$pct" ]] && printf "\e[K\e[54G%b ${N4}%s%%${R}" "$(bar "$pct" 10)" "$pct" ||
    printf "\e[K"
  printf "\n"
}

# ── Main Menu ─────────────────────────────────────────────────────────────────
render_menu() {
  printf "\e[H\n"
  local l1=' __   __       ___  __   __              __   ___      ___  __   ___ '
  local l2='/  ` /  \ |\ |  |  |__) /  \ |          /  ` |__  |\ |  |  |__) |__  '
  local l3='\__, \__/ | \|  |  |  \ \__/ |___       \__, |___ | \|  |  |  \ |___ '
  draw_header "$SR" "$l1" "$l2" "$l3" "$(date +%H:%M)"

  section "NETWORK"
  _row 0 "󰤨" "WiFi" "$C_WIFI"
  _row 1 "󰂯" "Bluetooth" "$C_BT"

  section "MEDIA"
  _row 2 "󰕾" "Volume" "$C_VOL" "$C_VOLP"
  _row 3 "󰍬" "Mic" "$C_MIC" "$C_MICP"
  _row 4 "󰃠" "Brightness" "" "$C_BR"

  section "ENVIRONMENT"
  _row 5 "󰖨" "Night Light" "$C_NL"
  _row 6 "󰒳" "Caffeine" "$C_CA"

  section "SYSTEM"
  _row 7 "󰍹" "Monitor Scaling"
  _row 8 "⏻" "Power Menu"

  printf "\n  ${N6}%s${R}\n" "$(printf '┄%.0s' {1..70})"
  _row 9 "󰅙" "Exit"
  printf "\n  ${N7}%s${R}\n" "$(printf '┄%.0s' {1..72})"
  printf "  ${N1}↑↓${R} ${N4}navigate${R}  ${N1}←→${R} ${N4}adjust${R}  ${N1}Enter${R} ${N4}select${R}  ${N1}q${R} ${N4}quit${R}\n"
  printf "\e[J"
}

# ── WiFi Submenu ──────────────────────────────────────────────────────────────
wifi_menu() {
  local wsel=0 wifi_on connected list_count=0
  local -A nets
  local scan_pid=""
  local scan_temp="/tmp/wifi_scan_$$"
  local scan_running=0
  local last_refresh=0

  _wifi_background_scan() {
    nmcli dev wifi rescan >/dev/null 2>&1
    nmcli --terse --fields SSID,SIGNAL,SECURITY dev wifi list >"$scan_temp" 2>/dev/null
  }

  _wifi_fetch_results() {
    list_count=0
    nets=()
    wifi_on=$(wifi_state)
    connected=""
    [[ "$wifi_on" == "OFF" ]] && return

    connected=$(nmcli -t -f active,ssid dev wifi 2>/dev/null |
      awk -F: '$1=="yes"{print $2; exit}')
    connected="${connected//$'\r'/}"

    if [[ -f "$scan_temp" ]] && [[ -s "$scan_temp" ]]; then
      local seen=""
      while IFS=':' read -r ssid signal sec; do
        [[ -z "$ssid" ]] && continue
        [[ "$seen" == *"|$ssid|"* ]] && continue
        seen+="|$ssid|"
        nets["ssid_$list_count"]="$ssid"
        nets["sig_$list_count"]="${signal// /}"
        nets["sec_$list_count"]="$sec"
        ((list_count++))
        ((list_count >= 10)) && break
      done <"$scan_temp"
    fi
    # No cache file yet — return empty; background scan will populate it
  }

  _wifi_start_scan() {
    [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
    _wifi_background_scan &
    scan_pid=$!
    scan_running=1
  }

  _wifi_draw() {
    local total=$((list_count + 2))
    ((wsel >= total)) && wsel=$((total - 1))

    clear_screen
    printf "\n"
    local l1='        ___   '
    local l2='|  | | |__  | '
    local l3='|/\| | |    | '
    draw_header "$SR" "$l1" "$l2" "$l3"

    if ((wsel == 0)); then
      printf "  ${BGSEL}${BL}${B} 󰤨  %-24s${R}" "WiFi"
    else
      printf "  ${N1}󰤨${R}  ${N2}%-24s${R}" "WiFi"
    fi
    printf "  %b\e[K\n" "$(dot "$wifi_on")"

    if [[ "$wifi_on" == "OFF" ]]; then
      printf "\n  ${N5}WiFi is disabled. Select above to enable.${R}\n"
    elif ((list_count == 0)); then
      printf "\n  ${N5}Scanning for networks...${R}\n"
      if [[ $scan_running -eq 1 ]]; then
        printf "  ${N6}Background scan in progress...${R}\n"
      else
        printf "  ${N6}Press any key to refresh.${R}\n"
      fi
    else
      printf "\n"
      for ((i = 0; i < list_count; i++)); do
        local ssid="${nets["ssid_$i"]}" sig="${nets["sig_$i"]}" sec="${nets["sec_$i"]}"
        local row=$((i + 1))
        [[ -z "$sig" ]] && sig="0"

        if ((wsel == row)); then
          printf "      ${BGSEL}${BL}${B} %-22.22s${R}" "$ssid"
        else
          printf "      ${N2} %-22.22s${R}" "$ssid"
        fi

        printf "\e[32G %b ${N4}%3s%%${R}" "$(bar "$sig" 8)" "$sig"
        [[ "$sec" == *"WPA"* ]] && printf "\e[46G${N5}[WPA]${R}" ||
          printf "\e[46G${N5}[Open]${R}"
        [[ "$ssid" == "$connected" ]] && printf "\e[54G${SG}${B}●${R} ${SG}connected${R}"
        printf "\e[K\n"
      done
    fi

    printf "\n  ${N6}%s${R}\n" "$(printf '┄%.0s' {1..72})"
    local back_row=$((total - 1))
    if ((wsel == back_row)); then
      printf "  ${BGSEL}${BL}${B} ←  Back%-14s${R}\e[K\n" ""
    else
      printf "  ${N1}←${R}  ${N2}Back${R}\n"
    fi
    printf "\n  ${N1}↑↓${R} ${N4}navigate${R}  ${N1}Enter${R} ${N4}select${R}  ${N1}q${R} ${N4}back${R}\n"
    printf "  ${N6}(Auto‑refresh every 5s, non‑blocking)${R}\n"
  }

  wifi_on=$(wifi_state)
  if [[ "$wifi_on" == "ON" ]]; then
    _wifi_start_scan
  fi
  _wifi_fetch_results
  _wifi_draw
  last_refresh=$(date +%s)

  while true; do
    local key
    key=$(read_key)
    local now=$(date +%s)

    if [[ -n "$scan_pid" ]] && ! kill -0 "$scan_pid" 2>/dev/null; then
      scan_running=0
      _wifi_fetch_results
      _wifi_draw
      if [[ "$wifi_on" == "ON" ]]; then
        _wifi_start_scan
        last_refresh=$now
      fi
    fi

    if [[ -z "$key" && $scan_running -eq 0 && "$wifi_on" == "ON" ]]; then
      if ((now - last_refresh >= 5)); then
        _wifi_start_scan
        last_refresh=$now
      fi
    fi

    if [[ -z "$key" ]]; then
      continue
    fi

    local total=$((list_count + 2))

    case "$key" in
    UP)
      ((wsel--))
      ((wsel < 0)) && wsel=$((total - 1))
      _wifi_draw
      ;;
    DOWN)
      ((wsel++))
      ((wsel >= total)) && wsel=0
      _wifi_draw
      ;;
    ENTER)
      if ((wsel == 0)); then
        toggle_wifi
        sleep 0.5
        if [[ "$(wifi_state)" == "ON" ]]; then
          _wifi_fetch_results
          _wifi_start_scan
        else
          [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
          scan_running=0
          _wifi_fetch_results
        fi
        _wifi_draw
      elif ((wsel == total - 1)); then
        [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
        rm -f "$scan_temp"
        clear_screen
        return
      elif [[ "$wifi_on" == "ON" ]] && ((list_count > 0)); then
        local idx=$((wsel - 1))
        local target="${nets["ssid_$idx"]}"
        if [[ "$target" == "$connected" ]]; then
          nmcli device disconnect wlan0 2>/dev/null
        else
          if ! nmcli device wifi connect "$target" 2>/dev/null; then
            printf "\n\n  ${SY}Password for %s:${R} " "$target"
            stty "$OLD_STTY"
            show_cursor
            local pwd=""
            read -r pwd
            hide_cursor
            stty -echo -icanon
            printf "\n"
            nmcli device wifi connect "$target" password "$pwd" 2>/dev/null
            sleep 1
          fi
        fi
        sleep 1
        _wifi_fetch_results
        _wifi_draw
      fi
      ;;
    OTHER)
      if [[ "$wifi_on" == "ON" ]]; then
        [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
        _wifi_start_scan
        _wifi_draw
      fi
      ;;
    QUIT)
      [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
      rm -f "$scan_temp"
      clear_screen
      return
      ;;
    esac
  done
}

# ── Bluetooth Submenu ─────────────────────────────────────────────────────────
bluetooth_menu() {
  local bsel=0
  local -a addrs names status disc_addrs disc_names
  local dev_count=0 disc_count=0
  local scan_pid=""
  local scan_temp="/tmp/bluetooth_scan_$$"
  local bt_on=""
  local scan_running=0
  local last_refresh=0

  _bt_ensure_ready() {
    bluetoothctl power on >/dev/null 2>&1
    bluetoothctl agent on >/dev/null 2>&1
    bluetoothctl default-agent >/dev/null 2>&1
    bluetoothctl discoverable on >/dev/null 2>&1
    bluetoothctl discoverable-timeout 0 >/dev/null 2>&1
  }

  _bt_clear_stale_cache() {
    local paired_addrs=""
    while read -r line; do
      [[ "$line" =~ ^Device[[:space:]]([0-9A-Fa-f:]+) ]] &&
        paired_addrs+="|${BASH_REMATCH[1]}"
    done < <(bluetoothctl paired-devices 2>/dev/null)
    while read -r line; do
      [[ "$line" =~ ^Device[[:space:]]([0-9A-Fa-f:]+) ]] || continue
      local addr="${BASH_REMATCH[1]}"
      [[ "$paired_addrs" == *"|$addr"* ]] && continue
      bluetoothctl remove "$addr" >/dev/null 2>&1
    done < <(bluetoothctl devices 2>/dev/null)
  }

  _bt_background_scan() {
    (
      echo "scan on"
      sleep 6
      echo "scan off"
    ) | bluetoothctl >/dev/null 2>&1
    bluetoothctl devices >"$scan_temp" 2>/dev/null
  }

  _bt_fetch_results() {
    bt_on=$(bt_state)
    addrs=()
    names=()
    status=()
    dev_count=0
    disc_addrs=()
    disc_names=()
    disc_count=0

    [[ "$bt_on" == "OFF" ]] && return

    local paired_lookup=""
    while read -r line; do
      [[ "$line" =~ ^Device[[:space:]]([0-9A-Fa-f:]+)[[:space:]](.+)$ ]] || continue
      local addr="${BASH_REMATCH[1]}" name="${BASH_REMATCH[2]}"
      local st="paired"
      bluetoothctl info "$addr" 2>/dev/null | grep -q "Connected: yes" && st="connected"
      addrs+=("$addr")
      names+=("$name")
      status+=("$st")
      paired_lookup+="|$addr"
      ((dev_count++))
    done < <(bluetoothctl paired-devices 2>/dev/null)

    if [[ -f "$scan_temp" ]]; then
      while read -r line; do
        [[ "$line" =~ ^Device[[:space:]]([0-9A-Fa-f:]+)[[:space:]](.+)$ ]] || continue
        local addr="${BASH_REMATCH[1]}" name="${BASH_REMATCH[2]}"
        [[ "$paired_lookup" == *"|$addr"* ]] && continue
        if [[ "$name" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
          name="Device (${addr})"
        fi
        disc_addrs+=("$addr")
        disc_names+=("$name")
        ((disc_count++))
      done <"$scan_temp"
    fi
  }

  _bt_start_scan() {
    if [[ -n "$scan_pid" ]] && kill -0 "$scan_pid" 2>/dev/null; then
      kill "$scan_pid" 2>/dev/null
      wait "$scan_pid" 2>/dev/null
    fi
    _bt_background_scan &
    scan_pid=$!
    scan_running=1
  }

  _bt_draw() {
    local total=$((dev_count + disc_count + 2))
    ((bsel >= total)) && bsel=$((total - 1))

    clear_screen
    printf "\n"
    local l1=' __             ___ ___  __   __  ___      '
    local l2='|__) |    |  | |__   |  /  \ /  \  |  |__| '
    local l3='|__) |___ \__/ |___  |  \__/ \__/  |  |  | '
    draw_header "$SR" "$l1" "$l2" "$l3"

    if ((bsel == 0)); then
      printf "  ${BGSEL}${BL}${B} 󰂯  %-24s${R}" "Bluetooth"
    else
      printf "  ${N1}󰂯${R}  ${N2}%-24s${R}" "Bluetooth"
    fi
    printf "  %b\e[K\n" "$(dot "$bt_on")"

    if [[ "$bt_on" == "OFF" ]]; then
      printf "\n  ${N5}Bluetooth is disabled. Select above to enable.${R}\n"
    else
      if ((dev_count > 0)); then
        printf "\n  ${N6}┄┄┄┄ ${N5}${B}Paired${R}\n"
        for ((i = 0; i < dev_count; i++)); do
          local row=$((i + 1))
          if ((bsel == row)); then
            printf "      ${BGSEL}${BL}${B} %-22.22s${R}" "${names[$i]}"
          else
            printf "      ${N2} %-22.22s${R}" "${names[$i]}"
          fi
          if [[ "${status[$i]}" == "connected" ]]; then
            printf "\e[32G${SG}${B}●${R} ${SG}connected${R}"
          else
            printf "\e[32G${N5}○${R} ${N5}paired${R}"
          fi
          printf "\e[K\n"
        done
      fi

      if ((disc_count > 0)); then
        printf "\n  ${N6}┄┄┄┄ ${N5}${B}Available${R}  ${N6}(Enter to pair & connect)${R}\n"
        for ((i = 0; i < disc_count; i++)); do
          local row=$((dev_count + 1 + i))
          if ((bsel == row)); then
            printf "      ${BGSEL}${BL}${B} %-22.22s${R}\e[K\n" "${disc_names[$i]}"
          else
            printf "      ${N2} %-22.22s${R}\n" "${disc_names[$i]}"
          fi
        done
      fi

      if ((dev_count == 0 && disc_count == 0)); then
        printf "\n  ${N5}Scanning for devices...${R}\n"
        printf "  ${N6}Make sure your device is in pairing mode.${R}\n"
      fi
      if [[ $scan_running -eq 1 ]]; then
        printf "\n  ${N6}⏳ Scanning in background... (refreshes in a few seconds)${R}\n"
      fi
    fi

    printf "\n  ${N6}%s${R}\n" "$(printf '┄%.0s' {1..72})"
    local back_row=$((total - 1))
    if ((bsel == back_row)); then
      printf "  ${BGSEL}${BL}${B} ←  Back%-14s${R}\e[K\n" ""
    else
      printf "  ${N1}←${R}  ${N2}Back${R}\n"
    fi
    printf "\n  ${N1}↑↓${R} ${N4}navigate${R}  ${N1}Enter${R} ${N4}select${R}  ${N1}q${R} ${N4}back${R}\n"
    printf "  ${N6}(Auto‑refresh every 4s, non‑blocking)${R}\n"
  }

  if [[ "$(bt_state)" == "ON" ]]; then
    _bt_ensure_ready
    _bt_clear_stale_cache
    _bt_start_scan
  fi
  _bt_fetch_results
  _bt_draw
  last_refresh=$(date +%s)

  while true; do
    local key
    key=$(read_key)
    local now=$(date +%s)

    if [[ -n "$scan_pid" ]] && ! kill -0 "$scan_pid" 2>/dev/null; then
      scan_running=0
      _bt_fetch_results
      _bt_draw
      if [[ "$bt_on" == "ON" ]]; then
        _bt_start_scan
        last_refresh=$now
      fi
    fi

    if [[ -z "$key" && $scan_running -eq 0 && "$bt_on" == "ON" ]]; then
      if ((now - last_refresh >= 4)); then
        _bt_start_scan
        last_refresh=$now
      fi
    fi

    if [[ -z "$key" ]]; then
      continue
    fi

    local total=$((dev_count + disc_count + 2))

    case "$key" in
    UP)
      ((bsel--))
      ((bsel < 0)) && bsel=$((total - 1))
      _bt_draw
      ;;
    DOWN)
      ((bsel++))
      ((bsel >= total)) && bsel=0
      _bt_draw
      ;;
    ENTER)
      if ((bsel == 0)); then
        toggle_bt
        sleep 0.5
        if [[ "$(bt_state)" == "ON" ]]; then
          _bt_ensure_ready
          _bt_clear_stale_cache
          _bt_start_scan
        else
          [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
          scan_running=0
        fi
        _bt_fetch_results
        _bt_draw
      elif ((bsel == total - 1)); then
        [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
        rm -f "$scan_temp"
        clear_screen
        return
      elif [[ "$bt_on" == "ON" ]] && ((bsel <= dev_count)); then
        local idx=$((bsel - 1))
        printf "\n\n  ${PU}${B}Attempting to ${status[$idx]}...${R}\n"
        if [[ "${status[$idx]}" == "connected" ]]; then
          bluetoothctl disconnect "${addrs[$idx]}" >/dev/null 2>&1
        else
          bluetoothctl connect "${addrs[$idx]}" >/dev/null 2>&1
        fi
        sleep 1
        _bt_fetch_results
        _bt_draw
      elif [[ "$bt_on" == "ON" ]] && ((bsel > dev_count)); then
        local idx=$((bsel - dev_count - 1))
        local target="${disc_addrs[$idx]}"
        local target_name="${disc_names[$idx]}"
        printf "\n\n  ${PU}${B}Pairing with %s...${R}\n" "$target_name"
        if bluetoothctl pair "$target" >/dev/null 2>&1; then
          echo "  ${SG}Pairing successful${R}"
          sleep 1
          bluetoothctl trust "$target" >/dev/null 2>&1
          echo "  ${SG}Device trusted${R}"
          sleep 0.5
          bluetoothctl connect "$target" >/dev/null 2>&1
          echo "  ${SG}Connecting...${R}"
          sleep 2
        else
          printf "  ${SR}Pairing failed. Make sure device is still discoverable.${R}\n"
          sleep 2
        fi
        _bt_fetch_results
        _bt_draw
      fi
      ;;
    OTHER)
      if [[ "$bt_on" == "ON" ]]; then
        [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
        _bt_start_scan
        _bt_draw
      fi
      ;;
    QUIT)
      [[ -n "$scan_pid" ]] && kill "$scan_pid" 2>/dev/null
      rm -f "$scan_temp"
      clear_screen
      return
      ;;
    esac
  done
}

# ── Power Menu ────────────────────────────────────────────────────────────────
power_menu() {
  local psel=0 pmax=5

  _prow() {
    if ((psel == $1)); then
      printf "      ${BGSEL}${BL}${B} %-22.22s${R}\e[K\n" "$2"
    else
      printf "      ${N2} %-22.22s${R}\n" "$2"
    fi
  }

  _confirm() {
    printf "\n  ${SR}${B}  Confirm: %s? ${N3}(y/n)${R} " "$1"
    local c
    IFS= read -rs -n1 c
    printf "\n"
    [[ "$c" == [yY] ]]
  }

  while true; do
    clear_screen
    printf "\n"
    local l1=' __   __        ___  __            ___           '
    local l2='|__) /  \ |  | |__  |__)     |\/| |__  |\ | |  | '
    local l3='|    \__/ |/\| |___ |  \     |  | |___ | \| \__/ '
    draw_header "$SR" "$l1" "$l2" "$l3"

    _prow 0 "Logout"
    _prow 1 "Lock Screen"
    _prow 2 "Reboot"
    _prow 3 "Reboot to BIOS"
    _prow 4 "Arch Reboot"
    _prow 5 "Shutdown"

    printf "\n  ${N6}%s${R}\n" "$(printf '┄%.0s' {1..72})"
    if ((psel == 6)); then
      printf "  ${BGSEL}${BL}${B} ←  Back%-14s${R}\e[K\n" ""
    else
      printf "  ${N1}←${R}  ${N2}Back${R}\n"
    fi
    printf "\n  ${N1}↑↓${R} ${N4}navigate${R}  ${N1}Enter${R} ${N4}select${R}  ${N1}q${R} ${N4}cancel${R}\n"

    local key
    key=$(read_key)
    case "$key" in
    UP)
      ((psel--))
      ((psel < 0)) && psel=6
      ;;
    DOWN)
      ((psel++))
      ((psel > 6)) && psel=0
      ;;
    ENTER)
      case "$psel" in
      0) _confirm "Logout" && {
        hyprctl dispatch exit
        cleanup
      } ;;
      1) _confirm "Lock screen" && {
        loginctl lock-session
        cleanup
      } ;;
      2) _confirm "Reboot" && {
        systemctl reboot
        cleanup
      } ;;
      3) _confirm "Reboot to BIOS" && {
        systemctl reboot --firmware-setup
        cleanup
      } ;;
      4) _confirm "Arch reboot" && {
        ~/.config/scripts/arch_reboot.sh
        cleanup
      } ;;
      5) _confirm "Shutdown" && {
        systemctl poweroff
        cleanup
      } ;;
      6)
        clear_screen
        return
        ;;
      esac
      sleep 0.4
      ;;
    QUIT)
      clear_screen
      return
      ;;
    esac
  done
}

# ── Cleanup & Exit ────────────────────────────────────────────────────────────
cleanup() {
  clear_screen
  show_cursor
  main_screen
  exit 0
}

# ── Main Loop ─────────────────────────────────────────────────────────────────
main() {
  OLD_STTY=$(stty -g)
  stty -echo -icanon
  trap 'stty "$OLD_STTY"; show_cursor; main_screen' EXIT

  alt_screen
  hide_cursor
  clear_screen
  SEL=0
  local max=9
  refresh_state

  while true; do
    render_menu
    local key
    key=$(read_key)
    [[ -z "$key" ]] && continue

    case "$key" in
    UP)
      ((SEL--))
      ((SEL < 0)) && SEL=$max
      ;;
    DOWN)
      ((SEL++))
      ((SEL > max)) && SEL=0
      ;;
    LEFT)
      case "$SEL" in
      2) adj_vol 5 - ;; 3) adj_mic 5 - ;;
      4) adj_bright - ;; 7) zoom_out ;;
      esac
      refresh_state
      ;;
    RIGHT)
      case "$SEL" in
      2) adj_vol 5 + ;; 3) adj_mic 5 + ;;
      4) adj_bright + ;; 7) zoom_in ;;
      esac
      refresh_state
      ;;
    ENTER)
      case "$SEL" in
      0)
        wifi_menu
        refresh_state
        ;;
      1)
        bluetooth_menu
        refresh_state
        ;;
      2) toggle_vol ;;
      3) toggle_mic ;;
      5) cycle_nl ;;
      6) toggle_caffeine ;;
      8) power_menu ;;
      9) cleanup ;;
      esac
      refresh_state
      ;;
    QUIT) cleanup ;;
    esac
  done
}

main "$@"
