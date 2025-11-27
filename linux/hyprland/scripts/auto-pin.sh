#!/usr/bin/env bash
# Auto-pin windows when they become floating or are opened floating
# Usage: auto-pin.sh [class|title:pattern]
# Example: auto-pin.sh mpv
# Example: auto-pin.sh "title:Picture in picture"
#
# Note: Pinned windows cannot go fullscreen in Hyprland.
# Use Super+Y to manually unpin before fullscreening.

pattern="$1"
lockdir="/tmp/hypr-auto-pin-locks"
mkdir -p "$lockdir"

while read -r line; do
    case "$line" in
        openwindow*)
            addr="${line#*>>}"
            addr="${addr%%,*}"
            sleep 0.2  # Let window settle
            ;;
        changefloatingmode*)
            addr="${line#*>>}"
            addr="${addr%%,*}"
            ;;
        *) continue ;;
    esac

    # Per-address lock to prevent double-processing
    lockfile="$lockdir/$addr"
    if [[ -f "$lockfile" ]] && [[ $(find "$lockfile" -mmin -0.05 2>/dev/null) ]]; then
        continue
    fi

    # Get window info
    read -r floating pinned class title < <(hyprctl clients -j | jq -r ".[] | select(.address == \"0x$addr\") | [.floating, .pinned, .class, .title] | @tsv")

    [[ "$floating" != "true" ]] && continue
    [[ "$pinned" == "true" ]] && continue

    # Check pattern match
    if [[ "$pattern" == title:* ]]; then
        [[ "$title" != "${pattern#title:}" ]] && continue
    else
        [[ "$class" != "$pattern" ]] && continue
    fi

    # Pin the window
    touch "$lockfile"
    hyprctl dispatch pin address:0x"$addr"
    sleep 0.3
    rm -f "$lockfile"
done < <(socat -t 999999 - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
