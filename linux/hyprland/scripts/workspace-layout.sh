#!/usr/bin/env bash

CACHE_FILE="$HOME/.cache/hypr/workspace-layouts"
mkdir -p "$(dirname "$CACHE_FILE")"
touch "$CACHE_FILE"

# Format: workspace=layout:master_address

get_entry() {
    grep "^$1=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2
}

set_entry() {
    local ws="$1" value="$2"
    if grep -q "^$ws=" "$CACHE_FILE" 2>/dev/null; then
        sed -i "s|^$ws=.*|$ws=$value|" "$CACHE_FILE"
    else
        echo "$ws=$value" >> "$CACHE_FILE"
    fi
}

get_master() {
    local ws="$1"
    # Master window is at top-left position (smallest x, then smallest y)
    hyprctl clients -j | jq -r --arg ws "$ws" \
        '[.[] | select(.workspace.id == ($ws | tonumber) and .floating == false)] | min_by(.at[0]) | .address // empty'
}

# Use env var WORKSPACE if set, otherwise get active
WS="${WORKSPACE:-$(hyprctl activeworkspace -j | jq -r '.id')}"

case "$1" in
    toggle)
        CURRENT=$(hyprctl getoption general:layout -j | jq -r '.str')
        if [ "$CURRENT" = "dwindle" ]; then
            NEW="master"
        else
            NEW="dwindle"
        fi
        hyprctl keyword general:layout "$NEW"
        MASTER=$(get_master "$WS")
        set_entry "$WS" "$NEW:$MASTER"
        ;;
    save)
        LAYOUT=$(hyprctl getoption general:layout -j | jq -r '.str')
        MASTER=$(get_master "$WS")
        set_entry "$WS" "$LAYOUT:$MASTER"
        ;;
    restore)
        ENTRY=$(get_entry "$WS")
        if [ -n "$ENTRY" ]; then
            LAYOUT="${ENTRY%%:*}"
            MASTER="${ENTRY#*:}"
            hyprctl keyword general:layout "$LAYOUT"
            if [ "$LAYOUT" = "master" ] && [ -n "$MASTER" ] && [ "$MASTER" != "empty" ]; then
                # Check window still exists on this workspace
                EXISTS=$(hyprctl clients -j | jq -r --arg addr "$MASTER" --arg ws "$WS" \
                    '.[] | select(.address == $addr and .workspace.id == ($ws | tonumber)) | .address')
                if [ -n "$EXISTS" ]; then
                    # Get current master
                    CURRENT_MASTER=$(get_master "$WS")
                    if [ "$CURRENT_MASTER" != "$MASTER" ]; then
                        hyprctl dispatch focuswindow "address:$MASTER"
                        hyprctl dispatch layoutmsg swapwithmaster
                    fi
                fi
            fi
        fi
        ;;
esac
