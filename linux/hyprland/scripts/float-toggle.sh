#!/usr/bin/env bash
# re-pins PiP windows if they remain floating after toggle

read -r addr floating pinned title < <(hyprctl activewindow -j | jq -r '[.address, .floating, .pinned, .title] | @tsv')

is_pip=false
[[ "$title" == *"Picture in picture"* || "$title" == *"Picture-in-Picture"* ]] && is_pip=true

if [[ "$is_pip" == "true" ]]; then
    # unpin first since toggling float on pinned window unpins but doesn't tile
    [[ "$pinned" == "true" ]] && hyprctl dispatch pin "address:$addr"
    sleep 0.05

    hyprctl dispatch togglefloating "address:$addr"
    sleep 0.1

    # re-pin if still floating
    new_floating=$(hyprctl clients -j | jq -r --arg a "$addr" '.[] | select(.address == $a) | .floating')
    [[ "$new_floating" == "true" ]] && hyprctl dispatch pin "address:$addr"
else
    hyprctl dispatch togglefloating
fi
