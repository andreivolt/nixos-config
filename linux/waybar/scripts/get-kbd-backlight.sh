#!/usr/bin/env bash

USER_DISABLED="/tmp/kbd-backlight-user-disabled"

if ! command -v brightnessctl &>/dev/null; then
  echo '{"text": "", "tooltip": "brightnessctl not found"}'
  exit 0
fi

if brightnessctl -d kbd_backlight info &>/dev/null; then
  percent=$(brightnessctl -d kbd_backlight -m | cut -d',' -f4 | tr -d '%')
  percent=${percent:-0}

  if [ -f "$USER_DISABLED" ]; then
    class="off"
    tooltip="Keyboard backlight: disabled"
  else
    class="on"
    tooltip="Keyboard backlight: enabled ($percent%)"
  fi
  echo "{\"text\": \"󰌌\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
else
  echo '{"text": "", "tooltip": "No keyboard backlight"}'
fi
