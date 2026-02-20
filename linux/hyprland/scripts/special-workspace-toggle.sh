#!/usr/bin/env bash
# Toggle special workspace with unpin/re-pin so it renders above pinned windows
# Usage: special-workspace-toggle.sh <workspace> [focus-class]

ws="$1"
focus_class="$2"
unpinned_file="/tmp/hypr-${ws}-unpinned"

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

visible=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')

if [[ "$visible" == "special:$ws" ]]; then
    # Hiding via keybind → re-pin and hide
    batch="dispatch togglespecialworkspace $ws"
    if [[ -f "$unpinned_file" ]]; then
        while read -r addr; do
            batch+=";dispatch pin address:${addr}"
        done < "$unpinned_file"
        rm -f "$unpinned_file"
    fi
    exec hyprctl --batch "$batch"
fi

# Re-pin leftovers from a previous toggle that was dismissed without the keybind
repin

# Showing → unpin all pinned windows
clients_json=$(hyprctl clients -j)
pinned_addrs=$(jq -r '.[] | select(.pinned) | .address' <<< "$clients_json")
batch=""
if [[ -n "$pinned_addrs" ]]; then
    > "$unpinned_file"
    while read -r addr; do
        batch+="dispatch pin address:${addr};"
        echo "$addr" >> "$unpinned_file"
    done <<< "$pinned_addrs"
fi

batch+="dispatch togglespecialworkspace $ws"
[[ -n "$focus_class" ]] && batch+=";dispatch focuswindow class:$focus_class"

# Background watcher: re-pin when workspace hides (covers dismiss via Escape, app close, etc.)
(
    socat -t 999999 - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
        if [[ "$line" == activespecial\>\>* ]]; then
            ws_name="${line#activespecial>>}"
            ws_name="${ws_name%%,*}"
            if [[ "$ws_name" != "special:$ws" ]]; then
                repin
                break
            fi
        fi
    done
) &

exec hyprctl --batch "$batch"
