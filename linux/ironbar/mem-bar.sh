#!/bin/sh
# Memory usage as a vertical bar PNG (physical pixels for 1.6x HiDPI)
eval "$(awk '/MemTotal/{printf "t=%d\n",$2}/MemAvailable/{printf "a=%d\n",$2}' /proc/meminfo)"
pct=$((100*(t-a)/t))

# Color based on usage
if [ "$pct" -ge 80 ]; then
  color='#cc6666'
elif [ "$pct" -ge 50 ]; then
  color='#b09a6d'
else
  color='#7a756d'
fi

# 10x22 physical pixels = ~6x14 logical @ 1.6x
w=10 h=22
fill=$((h * pct / 100))
[ "$fill" -lt 1 ] && [ "$pct" -gt 0 ] && fill=1
empty=$((h - fill))

out=/tmp/ironbar-mem-bar.png
convert -size ${w}x${h} xc:'#3c3a36' \
  -fill "$color" -draw "rectangle 0,$empty,$((w-1)),$((h-1))" \
  -define png:color-type=2 "$out" 2>/dev/null
echo "$out"
