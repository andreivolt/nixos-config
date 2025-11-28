#!/usr/bin/env bash
# Run this after restarting Hyprland with hyprland-git

set -e

echo "Updating hyprpm headers..."
hyprpm update

echo "Adding hyprWorkspaceLayouts plugin..."
hyprpm add https://github.com/zakk4223/hyprWorkspaceLayouts

echo "Enabling plugin..."
hyprpm enable hyprWorkspaceLayouts

echo ""
echo "Done! Now update your hyprland.conf:"
echo "1. Change layout = master to layout = workspacelayout"
echo "2. Change keybind to: bind = \$mainMod, Space, layoutmsg, setlayout master"
echo "   (toggles to master, use 'setlayout dwindle' for dwindle)"
echo ""
echo "Reload with: hyprctl reload"
