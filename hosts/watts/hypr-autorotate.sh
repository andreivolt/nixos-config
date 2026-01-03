#!/usr/bin/env bash
# Auto-rotation for Hyprland using iio-sensor-proxy events
# Event-driven via monitor-sensor, no polling needed

STATE_FILE="/tmp/hypr-autorotate-orientation"

rotate() {
  local orientation=$1
  local transform

  case "$orientation" in
    normal)    transform=0 ;;
    bottom-up) transform=2 ;;
    left-up)   transform=1 ;;
    right-up)  transform=3 ;;
    *)         return ;;
  esac

  hyprctl keyword monitor "eDP-1,transform,$transform"
  hyprctl keyword 'device[wacom-pen-and-multitouch-sensor-finger]:transform' "$transform"
  hyprctl keyword 'device[wacom-pen-and-multitouch-sensor-pen]:transform' "$transform"
}

# Listen for Hyprland config reload events and re-apply orientation
watch_hyprland() {
  local socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  socat -u "UNIX-CONNECT:$socket" - 2>/dev/null | while read -r line; do
    if [[ "$line" == "configreloaded>>" ]]; then
      orientation=$(cat "$STATE_FILE" 2>/dev/null)
      [[ -n "$orientation" ]] && rotate "$orientation"
    fi
  done
}
watch_hyprland &

monitor-sensor | while read -r line; do
  # Match both initial state and change events:
  #   "=== Has accelerometer (orientation: normal)"
  #   "    Accelerometer orientation changed: left-up"
  case "$line" in
    *"orientation changed:"*)
      orientation="${line##*: }"
      echo "$orientation" > "$STATE_FILE"
      rotate "$orientation"
      ;;
    *"(orientation:"*)
      orientation="${line##*(orientation: }"
      orientation="${orientation%%,*}"  # strip ", tilt: ..." if present
      orientation="${orientation%)}"    # strip trailing ) if no comma
      echo "$orientation" > "$STATE_FILE"
      rotate "$orientation"
      ;;
  esac
done
