#!/usr/bin/env bash

# Toggle control center - kill if running, start if not
if pgrep -f "waybar-control-center-gui" > /dev/null; then
  pkill -f "waybar-control-center-gui"
  exit 0
fi

exec waybar-control-center-gui
