{
  writeShellScriptBin,
  systemd,
  procps,
  coreutils,
}:
writeShellScriptBin "caffeine" ''
  set -euo pipefail

  # Ensure XDG_RUNTIME_DIR is set for SSH sessions
  export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

  TIMERFILE="/tmp/caffeine-$USER.timer"

  is_active() {
    ! ${systemd}/bin/systemctl --user is-active --quiet hypridle
  }

  start_caffeine() {
    ${systemd}/bin/systemctl --user stop hypridle
    echo "Caffeine enabled"
  }

  stop_caffeine() {
    if [[ -f "$TIMERFILE" ]]; then
      ${procps}/bin/pkill -F "$TIMERFILE" 2>/dev/null || true
      ${coreutils}/bin/rm -f "$TIMERFILE"
    fi
    ${systemd}/bin/systemctl --user start hypridle
    echo "Caffeine disabled"
  }

  start_timed() {
    local minutes="$1"
    start_caffeine
    if [[ -f "$TIMERFILE" ]]; then
      ${procps}/bin/pkill -F "$TIMERFILE" 2>/dev/null || true
    fi
    (
      ${coreutils}/bin/sleep "''${minutes}m"
      ${systemd}/bin/systemctl --user start hypridle
      ${coreutils}/bin/rm -f "$TIMERFILE"
      ${procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
    ) &
    echo $! > "$TIMERFILE"
    disown
    echo "Auto-disable in $minutes minutes"
  }

  signal_waybar() {
    ${procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
  }

  case "''${1:-status}" in
    on)      start_caffeine; signal_waybar ;;
    off)     stop_caffeine; signal_waybar ;;
    toggle)
      if is_active; then stop_caffeine; else start_caffeine; fi
      signal_waybar
      ;;
    status)
      if is_active; then echo "ON"; else echo "OFF"; fi
      ;;
    waybar)
      if is_active; then
        echo '{"text": "󰛊", "tooltip": "Caffeine: ON", "class": "active"}'
      else
        echo '{"text": "󰛊", "tooltip": "Caffeine: OFF", "class": "inactive"}'
      fi
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        start_timed "$1"; signal_waybar
      else
        echo "Usage: caffeine [on|off|toggle|status|waybar|MINUTES]"
        exit 1
      fi
      ;;
  esac
''
