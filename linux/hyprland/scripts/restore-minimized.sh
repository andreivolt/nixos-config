#!/bin/sh
windows=$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:minimized") | "\(.address) \(.class): \(.title)"')
[ -z "$windows" ] && exit 0

selected=$(echo "$windows" | picker) || exit 0
addr=$(echo "$selected" | cut -d' ' -f1)
hyprctl dispatch movetoworkspace "e+0,address:$addr"
