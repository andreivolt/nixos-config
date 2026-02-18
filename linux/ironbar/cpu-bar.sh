#!/bin/sh
# CPU usage as a vertical bar PNG (physical pixels for 1.6x HiDPI)
state=/tmp/ironbar-cpu-state
if [ -f "$state" ]; then read -r u1 n1 s1 i1 < "$state"; fi
read -r _ u2 n2 s2 i2 _ < /proc/stat
echo "$u2 $n2 $s2 $i2" > "$state"

if [ -z "$u1" ]; then pct=0; else
  t1=$((u1+n1+s1+i1)) t2=$((u2+n2+s2+i2))
  d=$((t2-t1)); [ "$d" -eq 0 ] && d=1
  pct=$((100*(d-(i2-i1))/d))
fi

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

out=/tmp/ironbar-cpu-bar.png
convert -size ${w}x${h} xc:'#3c3a36' \
  -fill "$color" -draw "rectangle 0,$empty,$((w-1)),$((h-1))" \
  -define png:color-type=2 "$out" 2>/dev/null
echo "$out"
