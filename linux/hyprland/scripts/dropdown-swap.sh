#!/usr/bin/env bash
# Swap focused window into/out of the dropdown
# Evicts existing occupant to the grid when swapping in

active_json=$(hyprctl activewindow -j)
active_ws=$(jq -r '.workspace.name' <<< "$active_json")
active_addr=$(jq -r '.address' <<< "$active_json")
active_floating=$(jq -r '.floating' <<< "$active_json")

mon_json=$(hyprctl monitors -j)

if [[ "$active_ws" == "special:dropdown" ]]; then
    # Focused window is in the dropdown → send it back to the grid, reclaim terminal
    read -r mon_x mon_y eff_w eff_h mon_name target_ws < <(
        jq -r '.[] | select(.focused) | "\(.x) \(.y) \((.width/.scale)|floor) \((.height/.scale)|floor) \(.name) \(.activeWorkspace.id)"' <<< "$mon_json"
    )

    batch="dispatch movetoworkspacesilent ${target_ws},address:${active_addr}"
    [[ "$active_floating" == "true" ]] && batch+=";dispatch togglefloating address:${active_addr}"

    # Reclaim the dropdown terminal back into the dropdown
    clients_json=$(hyprctl clients -j)
    read -r term_addr term_floating < <(
        jq -r '.[] | select(.class == "dropdown") | "\(.address) \(.floating)"' <<< "$clients_json" | head -1
    )

    if [[ -n "$term_addr" && "$term_addr" != "$active_addr" ]]; then
        batch+=";dispatch movetoworkspacesilent special:dropdown,address:${term_addr}"
        [[ "$term_floating" != "true" ]] && batch+=";dispatch togglefloating address:${term_addr}"

        # Resize terminal to dropdown position
        bar_h=$(hyprctl layers -j | jq -r --arg mon "$mon_name" '.[$mon].levels | to_entries | .[] | .value[] | select(.namespace=="waybar") | .h' 2>/dev/null)
        bar_h=${bar_h:-40}
        drop_w=$((eff_w * 80 / 100))
        drop_h=$((eff_h * 62 / 100))
        drop_x=$((mon_x + (eff_w - drop_w) / 2))
        drop_y=$((mon_y + bar_h + 2))
        batch+=";dispatch resizewindowpixel exact ${drop_w} ${drop_h},address:${term_addr}"
        batch+=";dispatch movewindowpixel exact ${drop_x} ${drop_y},address:${term_addr}"
    fi

    batch+=";dispatch togglespecialworkspace dropdown"
    batch+=";dispatch focuswindow address:${active_addr}"

    exec hyprctl --batch "$batch"
else
    # Focused window is in the grid → swap it into the dropdown
    read -r mon_x mon_y eff_w eff_h mon_name current_ws < <(
        jq -r '.[] | select(.focused) | "\(.x) \(.y) \((.width/.scale)|floor) \((.height/.scale)|floor) \(.name) \(.activeWorkspace.id)"' <<< "$mon_json"
    )

    # Evict current occupant back to the grid
    clients_json=$(hyprctl clients -j)
    batch=""
    while IFS=$'\t' read -r addr floating; do
        [[ -z "$addr" ]] && continue
        batch+="dispatch movetoworkspacesilent ${current_ws},address:${addr};"
        [[ "$floating" == "true" ]] && batch+="dispatch togglefloating address:${addr};"
    done < <(jq -r '.[] | select(.workspace.name == "special:dropdown") | [.address, .floating] | @tsv' <<< "$clients_json")

    # Size/position (80% × 62%, centered below waybar)
    bar_h=$(hyprctl layers -j | jq -r --arg mon "$mon_name" '.[$mon].levels | to_entries | .[] | .value[] | select(.namespace=="waybar") | .h' 2>/dev/null)
    bar_h=${bar_h:-40}
    drop_w=$((eff_w * 80 / 100))
    drop_h=$((eff_h * 62 / 100))
    drop_x=$((mon_x + (eff_w - drop_w) / 2))
    drop_y=$((mon_y + bar_h + 2))

    # Move in, float, resize, show
    batch+="dispatch movetoworkspacesilent special:dropdown,address:${active_addr};"
    [[ "$active_floating" != "true" ]] && batch+="dispatch togglefloating address:${active_addr};"

    dropdown_visible=$(jq -r '.[] | select(.focused) | .specialWorkspace.name' <<< "$mon_json")
    [[ "$dropdown_visible" != "special:dropdown" ]] && batch+="dispatch togglespecialworkspace dropdown;"

    batch+="dispatch focuswindow address:${active_addr};"
    batch+="dispatch resizewindowpixel exact ${drop_w} ${drop_h},address:${active_addr};"
    batch+="dispatch movewindowpixel exact ${drop_x} ${drop_y},address:${active_addr}"

    exec hyprctl --batch "$batch"
fi
