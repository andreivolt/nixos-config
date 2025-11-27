#!/usr/bin/env bash
# Auto-pin Picture-in-Picture windows when they become floating

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
        changefloatingmode*)
            addr="${line#*>>}"
            addr="${addr%%,*}"

            # Get window info
            title=$(hyprctl clients -j | jq -r ".[] | select(.address == \"0x$addr\") | .title")
            floating=$(hyprctl clients -j | jq -r ".[] | select(.address == \"0x$addr\") | .floating")

            if [[ "$title" == "Picture in picture" && "$floating" == "true" ]]; then
                hyprctl dispatch pin address:0x"$addr"
            fi
            ;;
    esac
done
