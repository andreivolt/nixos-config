#!/usr/bin/env bash
# Toggle dropdown visibility; restores terminal if empty

unpinned_file="/tmp/hypr-dropdown-unpinned"

repin() {
    if [[ -f "$unpinned_file" ]]; then
        local batch=""
        while read -r addr; do
            batch+="${batch:+;}dispatch pin address:${addr}"
        done < "$unpinned_file"
        rm -f "$unpinned_file"
        [[ -n "$batch" ]] && hyprctl --batch "$batch"
    fi
}

mon_json=$(hyprctl monitors -j)
dropdown_visible=$(jq -r '.[] | select(.focused) | .specialWorkspace.name' <<< "$mon_json")

if [[ "$dropdown_visible" == "special:dropdown" ]]; then
    # Hiding dropdown → re-pin previously unpinned windows
    batch="dispatch togglespecialworkspace dropdown"
    if [[ -f /tmp/hypr-dropdown-unpinned ]]; then
        while read -r addr; do
            batch+=";dispatch pin address:${addr}"
        done < /tmp/hypr-dropdown-unpinned
        rm -f /tmp/hypr-dropdown-unpinned
    fi
    exec hyprctl --batch "$batch"
fi

# Dropdown is hidden → show it
read -r focused_mon mon_x mon_y eff_w eff_h mon_name < <(
    jq -r '.[] | select(.focused) | "\(.id) \(.x) \(.y) \((.width/.scale)|floor) \((.height/.scale)|floor) \(.name)"' <<< "$mon_json"
)

clients_json=$(hyprctl clients -j)
read -r occupant_addr occupant_mon < <(
    jq -r '.[] | select(.workspace.name == "special:dropdown") | "\(.address) \(.monitor // -1)"' <<< "$clients_json" | head -1
)

batch=""

# Re-pin leftovers from a previous toggle dismissed without the keybind
repin

# Unpin all pinned windows so dropdown renders on top
pinned_addrs=$(jq -r '.[] | select(.pinned) | .address' <<< "$clients_json")
if [[ -n "$pinned_addrs" ]]; then
    > /tmp/hypr-dropdown-unpinned
    while read -r addr; do
        batch+="dispatch pin address:${addr};"
        echo "$addr" >> /tmp/hypr-dropdown-unpinned
    done <<< "$pinned_addrs"
fi

if [[ -z "$occupant_addr" ]]; then
    # Empty → reclaim the dropdown terminal from wherever it landed
    read -r dropdown_addr dropdown_floating dropdown_mon < <(
        jq -r '.[] | select(.class == "dropdown") | "\(.address) \(.floating) \(.monitor // -1)"' <<< "$clients_json" | head -1
    )

    if [[ -n "$dropdown_addr" ]]; then
        batch+="dispatch movetoworkspacesilent special:dropdown,address:${dropdown_addr};"
        [[ "$dropdown_floating" != "true" ]] && batch+="dispatch togglefloating address:${dropdown_addr};"
        occupant_addr="$dropdown_addr"
        occupant_mon="$dropdown_mon"
    else
        # Terminal gone → restart service, wait for window rule to place it
        systemctl --user start dropdown.service
        for _ in {1..10}; do
            sleep 0.1
            occupant_addr=$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:dropdown") | .address' | head -1)
            [[ -n "$occupant_addr" ]] && break
        done
        occupant_mon="$focused_mon"
    fi
fi

# Size/position (full-width, 42% height, flush below bar)
bar_h=$(hyprctl layers -j | jq -r --arg mon "$mon_name" '[.[$mon].levels[][] | select(.w > .h * 2 and .h > 0 and .h < 200)] | .[0].h // 0')
drop_w=$eff_w
drop_h=$((eff_h * 62 / 100))
drop_x=$mon_x
drop_y=$((mon_y + bar_h))

# Background watcher: re-pin when dropdown hides (covers all dismiss paths)
(
    socat -t 999999 - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
        if [[ "$line" == activespecial\>\>* ]]; then
            ws_name="${line#activespecial>>}"
            ws_name="${ws_name%%,*}"
            if [[ "$ws_name" != "special:dropdown" ]]; then
                repin
                break
            fi
        fi
    done
) &

# Cross-monitor: resize while hidden to avoid slide artifact
if [[ "$occupant_mon" != "$focused_mon" && "$occupant_mon" != "-1" && -n "$occupant_addr" ]]; then
    batch+="keyword animations:enabled 0;"
    batch+="dispatch resizewindowpixel exact ${drop_w} ${drop_h},address:${occupant_addr};"
    batch+="dispatch movewindowpixel exact ${drop_x} ${drop_y},address:${occupant_addr};"
    batch+="dispatch togglespecialworkspace dropdown;"
    batch+="keyword animations:enabled 1"
    exec hyprctl --batch "$batch"
fi

# Same monitor: show with animation, then resize by address
batch+="dispatch togglespecialworkspace dropdown;"
batch+="dispatch resizewindowpixel exact ${drop_w} ${drop_h},address:${occupant_addr};"
batch+="dispatch movewindowpixel exact ${drop_x} ${drop_y},address:${occupant_addr}"
exec hyprctl --batch "$batch"
