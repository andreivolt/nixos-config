#!/usr/bin/env bash

if pgrep -x "dictate" > /dev/null 2>&1 || pgrep -f "whisper.*--model" > /dev/null 2>&1; then
  echo '{"text": "󰍬", "tooltip": "Recording...", "class": "recording"}'
else
  echo '{"text": "", "tooltip": "Idle", "class": "idle"}'
fi
