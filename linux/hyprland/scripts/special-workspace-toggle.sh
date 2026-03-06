#!/usr/bin/env bash
# Toggle special workspace visibility
# Usage: special-workspace-toggle.sh <workspace> [focus-class]

ws="$1"
focus_class="$2"

visible=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')

if [[ "$visible" == "special:$ws" ]]; then
    exec hyprctl dispatch togglespecialworkspace "$ws"
fi

batch="dispatch togglespecialworkspace $ws"
[[ -n "$focus_class" ]] && batch+=";dispatch focuswindow class:$focus_class"

exec hyprctl --batch "$batch"
