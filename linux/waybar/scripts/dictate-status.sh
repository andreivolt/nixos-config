#!/usr/bin/env bash

# Check dictate state file or process
STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dictate.state"
PID_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dictate.pid"

is_recording() {
  # Check state file
  [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE" 2>/dev/null)" == "recording" ]] || return 1
  # Verify process is actually running
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
}

if is_recording; then
  echo '{"text": "󰍬", "tooltip": "Recording...", "class": "recording"}'
else
  echo '{"text": "", "tooltip": "Idle", "class": "idle"}'
fi
