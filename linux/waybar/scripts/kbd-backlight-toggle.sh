#!/usr/bin/env bash
# Toggle keyboard backlight on/off, remembering last value
# Coordinates with kbd-backlight-idle service via USER_DISABLED flag

STATE_FILE="/tmp/kbd-backlight-last-value"
USER_DISABLED="/tmp/kbd-backlight-user-disabled"
DEFAULT_VALUE=100

if ! command -v brightnessctl &>/dev/null; then
  exit 1
fi

if ! brightnessctl -d kbd_backlight info &>/dev/null; then
  exit 1
fi

current=$(brightnessctl -d kbd_backlight -m | cut -d',' -f4 | tr -d '%')
current=${current:-0}

if [ "$current" -eq 0 ]; then
  # Currently off - restore last value and clear disable flag
  rm -f "$USER_DISABLED"
  if [ -f "$STATE_FILE" ]; then
    restore_value=$(cat "$STATE_FILE")
  else
    restore_value=$DEFAULT_VALUE
  fi
  brightnessctl -d kbd_backlight set "${restore_value}%" >/dev/null
else
  # Currently on - save value, turn off, and set disable flag
  echo "$current" > "$STATE_FILE"
  touch "$USER_DISABLED"
  brightnessctl -d kbd_backlight set 0% >/dev/null
fi
