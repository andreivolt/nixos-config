#!/bin/sh
# Watch hyprland events and update ironbar minimized count via ironvars
update() {
    n=$(hyprctl clients -j | jq '[.[] | select(.workspace.name == "special:minimized")] | length')
    if [ "$n" -gt 0 ]; then
        ironbar var set minimized_visible true
        ironbar var set minimized_count "󰖰 $n"
    else
        ironbar var set minimized_visible false
        ironbar var set minimized_count ""
    fi
}

update
socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r _; do
    update
done
