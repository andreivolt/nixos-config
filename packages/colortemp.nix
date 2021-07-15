#!/usr/bin/env bash

temp=$([ -f /tmp/colortemp ] && cat /tmp/colortemp || echo 6500)
incr=100

case $1 in
  up) temp=$((temp + $incr)) ;;
  down) temp=$((temp - $incr)) ;;
esac
echo $temp > /tmp/colortemp


pkill gammastep

echo $temp
exec setsid &>/dev/null gammastep -O $temp
