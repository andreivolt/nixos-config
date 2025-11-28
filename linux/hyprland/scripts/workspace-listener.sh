#!/usr/bin/env bash

# Prevent duplicate instances
LOCKFILE="/tmp/hypr-workspace-listener.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0
trap "rm -f '$LOCKFILE'" EXIT

SCRIPT_DIR="$(dirname "$0")"
LAST_WS_FILE="/tmp/hypr-last-workspace"
echo "$(hyprctl activeworkspace -j | jq -r '.id')" > "$LAST_WS_FILE"

while read -r line; do
    case "$line" in
        workspace\>*)
            # Save state of workspace we're leaving
            LAST_WS=$(cat "$LAST_WS_FILE")
            WORKSPACE="$LAST_WS" "$SCRIPT_DIR/workspace-layout.sh" save
            # Small delay to let hyprland finish switching
            sleep 0.05
            # Update to new workspace
            NEW_WS=$(hyprctl activeworkspace -j | jq -r '.id')
            echo "$NEW_WS" > "$LAST_WS_FILE"
            # Restore state of workspace we're entering
            "$SCRIPT_DIR/workspace-layout.sh" restore
            ;;
    esac
done < <(socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
