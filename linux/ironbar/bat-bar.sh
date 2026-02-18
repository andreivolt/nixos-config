#!/bin/sh
cat /sys/class/power_supply/macsmc-battery/capacity 2>/dev/null || echo 0
