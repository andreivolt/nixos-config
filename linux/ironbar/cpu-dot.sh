#!/bin/sh
state=/tmp/ironbar-cpu-state
if [ -f "$state" ]; then
    read -r u1 n1 s1 i1 < "$state"
fi
read -r _ u2 n2 s2 i2 _ < /proc/stat
echo "$u2 $n2 $s2 $i2" > "$state"
if [ -z "$u1" ]; then
    printf '<span foreground="#7a756d">●</span>'
    exit 0
fi
t1=$((u1+n1+s1+i1)) t2=$((u2+n2+s2+i2))
d=$((t2-t1))
[ "$d" -eq 0 ] && d=1
cpu=$((100*(d-(i2-i1))/d))
if [ "$cpu" -ge 80 ]; then printf '<span foreground="#c45050">●</span>'
elif [ "$cpu" -ge 50 ]; then printf '<span foreground="#d4a053">●</span>'
else printf '<span foreground="#7a756d">●</span>'
fi
