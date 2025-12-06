#!/usr/bin/env bash
# Brightness control with DPMS support (like macOS)
# Usage: brightness.sh up|down

WOB_SOCK="$XDG_RUNTIME_DIR/wob.sock"

get_percent() {
    brightnessctl -m | cut -d',' -f4 | tr -d '%'
}

send_wob() {
    echo "$1" > "$WOB_SOCK"
}

case "$1" in
    up)
        # If DPMS is off, turn it on
        if [ "$(hyprctl monitors -j | jq -r '.[0].dpmsStatus')" = "false" ]; then
            hyprctl dispatch dpms on
            send_wob "$(get_percent)"
        else
            brightnessctl s 1%+
            send_wob "$(get_percent)"
        fi
        ;;
    down)
        current=$(get_percent)
        if [ "$current" -le 1 ]; then
            # Already at minimum, turn off display
            sleep 0.2 && hyprctl dispatch dpms off
        else
            brightnessctl s 1%-
            send_wob "$(get_percent)"
        fi
        ;;
    *)
        echo "Usage: $0 up|down"
        exit 1
        ;;
esac
