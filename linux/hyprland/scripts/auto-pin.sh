#!/usr/bin/env bash
# Auto-pin windows when they become floating or are opened floating
# Usage: auto-pin-pip.sh [class|title:pattern]
# Example: auto-pin-pip.sh mpv
# Example: auto-pin-pip.sh "title:Picture in picture"

pattern="$1"

socat - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
        openwindow*)
            addr="${line#*>>}"
            addr="${addr%%,*}"
            # Delay to let window rules apply
            sleep 0.1
            ;&
        changefloatingmode*)
            [[ -z "$addr" ]] && { addr="${line#*>>}"; addr="${addr%%,*}"; }

            # Get window info
            info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"0x$addr\")")
            floating=$(echo "$info" | jq -r '.floating')
            class=$(echo "$info" | jq -r '.class')
            title=$(echo "$info" | jq -r '.title')

            [[ "$floating" != "true" ]] && { addr=""; continue; }

            if [[ "$pattern" == title:* ]]; then
                [[ "$title" == "${pattern#title:}" ]] && hyprctl dispatch pin address:0x"$addr"
            else
                [[ "$class" == "$pattern" ]] && hyprctl dispatch pin address:0x"$addr"
            fi
            addr=""
            ;;
    esac
done
