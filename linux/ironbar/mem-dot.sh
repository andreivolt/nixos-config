#!/bin/sh
eval "$(awk '/MemTotal/{printf "t=%d\n",$2}/MemAvailable/{printf "a=%d\n",$2}' /proc/meminfo)"
p=$((100*(t-a)/t))
if [ "$p" -ge 85 ]; then printf '<span foreground="#c45050">●</span>'
elif [ "$p" -ge 60 ]; then printf '<span foreground="#d4a053">●</span>'
else printf '<span foreground="#7a756d">●</span>'
fi
