#!/usr/bin/env bash

if ! command -v brightnessctl &>/dev/null; then
  echo '{"text": "", "tooltip": "brightnessctl not found"}'
  exit 0
fi

if brightnessctl -d kbd_backlight info &>/dev/null; then
  percent=$(brightnessctl -d kbd_backlight -m | cut -d',' -f4 | tr -d '%')
  percent=${percent:-0}
  if [ "$percent" -eq 0 ]; then
    class="off"
  elif [ "$percent" -le 33 ]; then
    class="low"
  elif [ "$percent" -le 66 ]; then
    class="medium"
  else
    class="high"
  fi
  echo "{\"text\": \"󰌌\", \"tooltip\": \"Keyboard backlight: $percent%\", \"percentage\": $percent, \"class\": \"$class\"}"
else
  echo '{"text": "", "tooltip": "No keyboard backlight"}'
fi
