#!/usr/bin/env bash

if ! command -v brightnessctl &>/dev/null; then
  echo '{"text": "", "tooltip": "brightnessctl not found"}'
  exit 0
fi

# Try common backlight devices
for device in apple-panel-bl intel_backlight amdgpu_bl0 acpi_video0; do
  if brightnessctl -d "$device" info &>/dev/null; then
    percent=$(brightnessctl -d "$device" -m | cut -d',' -f4 | tr -d '%')
    if [ "$percent" -ge 70 ]; then
      icon="󰃠"
    elif [ "$percent" -ge 40 ]; then
      icon="󰃟"
    else
      icon="󰃞"
    fi
    echo "{\"text\": \"$icon  $percent%\", \"tooltip\": \"Brightness: $percent%\", \"percentage\": $percent}"
    exit 0
  fi
done

echo '{"text": "", "tooltip": "No backlight found"}'
