#!/bin/sh
# Minimize active window: unpin first (pinned windows can't change workspace)
addr=$(hyprctl activewindow -j | jq -r '.address')
[ -z "$addr" ] || [ "$addr" = "null" ] && exit 0
pinned=$(hyprctl activewindow -j | jq -r '.pinned')
batch=""
[ "$pinned" = "true" ] && batch="dispatch pin address:$addr;"
batch="${batch}dispatch movetoworkspacesilent special:minimized,address:$addr"
hyprctl --batch "$batch"
