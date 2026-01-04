#!/usr/bin/env bash
# Toggle dropdown terminal with auto-sizing to current monitor
# Optimized: minimal hyprctl calls, pre-resize before showing

# Single call to get monitor state
mon_json=$(hyprctl monitors -j)
dropdown_active=$(jq -r '.[] | select(.focused) | .specialWorkspace.name' <<< "$mon_json")

if [[ "$dropdown_active" == "special:dropdown" ]]; then
    exec hyprctl dispatch togglespecialworkspace dropdown
fi

# Parse all monitor info in one jq call (id, x, y, effective_w, effective_h, monitor_name)
read -r focused_mon mon_x mon_y eff_w eff_h mon_name < <(jq -r '.[] | select(.focused) | "\(.id) \(.x) \(.y) \((.width/.scale)|floor) \((.height/.scale)|floor) \(.name)"' <<< "$mon_json")

# Get waybar height on focused monitor
bar_h=$(hyprctl layers -j | jq -r --arg mon "$mon_name" '.[$mon].levels | to_entries | .[] | .value[] | select(.namespace=="waybar") | .h' 2>/dev/null)
bar_h=${bar_h:-40}  # fallback to 40px if waybar not found

# Single call to get dropdown client info
client_json=$(hyprctl clients -j)
read -r current_mon addr < <(jq -r '.[] | select(.class=="dropdown") | "\(.monitor // -1) \(.address)"' <<< "$client_json")

# Calculate size/position (80% width, 62% height, centered, right below waybar)
drop_w=$((eff_w * 80 / 100))
drop_h=$((eff_h * 62 / 100))
drop_x=$((mon_x + (eff_w - drop_w) / 2))
drop_y=$((mon_y + bar_h + 2))

# Switching monitors: resize while hidden, then show (no animation to avoid cross-monitor slide)
if [[ "$current_mon" != "$focused_mon" && "$current_mon" != "-1" ]]; then
    exec hyprctl --batch "\
keyword animations:enabled 0;\
dispatch resizewindowpixel exact ${drop_w} ${drop_h},address:${addr};\
dispatch movewindowpixel exact ${drop_x} ${drop_y},address:${addr};\
dispatch togglespecialworkspace dropdown;\
keyword animations:enabled 1"
fi

# Same monitor: show with animation, then resize
hyprctl dispatch togglespecialworkspace dropdown
exec hyprctl --batch "dispatch focuswindow class:dropdown; dispatch resizeactive exact ${drop_w} ${drop_h}; dispatch moveactive exact ${drop_x} ${drop_y}"
