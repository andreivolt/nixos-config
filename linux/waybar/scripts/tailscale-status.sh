#!/usr/bin/env bash

if command -v tailscale &>/dev/null; then
  status=$(tailscale status --json 2>/dev/null)
  if [ $? -eq 0 ]; then
    exit_node=$(echo "$status" | jq -r '.ExitNodeStatus.TailscaleIPs[0] // empty')
    if [ -n "$exit_node" ]; then
      echo '{"text": "󰖂", "tooltip": "Exit node: '"$exit_node"'", "class": "connected"}'
    else
      online=$(echo "$status" | jq -r '.Self.Online')
      if [ "$online" = "true" ]; then
        echo '{"text": "󰖂", "tooltip": "Tailscale connected", "class": "connected"}'
      else
        echo '{"text": "", "tooltip": "Tailscale offline"}'
      fi
    fi
  else
    echo '{"text": "", "tooltip": "Tailscale not running"}'
  fi
else
  echo '{"text": "", "tooltip": "Tailscale not installed"}'
fi
