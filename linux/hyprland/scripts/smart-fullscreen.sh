#!/usr/bin/env bash
# Smart fullscreen: unpins window before fullscreening, re-pins on exit
# Usage: smart-fullscreen.sh [0|1]  (0=real fullscreen, 1=maximize)

mode="${1:-0}"

# Get active window info
read -r addr pinned fullscreen < <(hyprctl activewindow -j | jq -r '[.address, .pinned, .fullscreen] | @tsv')

if [[ "$fullscreen" != "0" ]]; then
    # Currently fullscreen - exit fullscreen
    hyprctl dispatch fullscreen "$mode"
    # Re-pin if we unpinned it (check temp file)
    if [[ -f "/tmp/hypr-was-pinned-$addr" ]]; then
        sleep 0.1
        hyprctl dispatch pin "address:$addr"
        rm -f "/tmp/hypr-was-pinned-$addr"
    fi
else
    # Not fullscreen - enter fullscreen
    if [[ "$pinned" == "true" ]]; then
        # Remember it was pinned
        touch "/tmp/hypr-was-pinned-$addr"
        # Unpin first
        hyprctl dispatch pin "address:$addr"
        sleep 0.1
    fi
    hyprctl dispatch fullscreen "$mode"
fi
