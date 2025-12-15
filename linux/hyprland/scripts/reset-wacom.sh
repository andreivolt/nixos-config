#!/usr/bin/env bash
# Reset Wacom touchscreen USB device when it enters zombie state
# (appears connected but generates no events)

for dev in /sys/bus/usb/devices/*; do
  if [ -f "$dev/idVendor" ] && [ -f "$dev/idProduct" ]; then
    vendor=$(cat "$dev/idVendor" 2>/dev/null)
    product=$(cat "$dev/idProduct" 2>/dev/null)
    if [ "$vendor" = "056a" ] && [ "$product" = "5087" ]; then
      echo 0 > "$dev/authorized" 2>/dev/null
      sleep 0.3
      echo 1 > "$dev/authorized" 2>/dev/null
      exit 0
    fi
  fi
done
