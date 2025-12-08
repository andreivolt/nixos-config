#!/usr/bin/env bash
# Caffeine toggle - prevents screen idle/sleep

PIDFILE="/tmp/caffeine-$USER.pid"
STATEFILE="/tmp/caffeine-$USER.state"

is_active() {
    [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

start_caffeine() {
    systemd-inhibit --what=idle:sleep:handle-lid-switch \
        --who="Caffeine" \
        --why="User requested" \
        --mode=block \
        sleep infinity &
    echo $! > "$PIDFILE"
    echo "on" > "$STATEFILE"
}

stop_caffeine() {
    if [[ -f "$PIDFILE" ]]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
    fi
    echo "off" > "$STATEFILE"
}

status() {
    if is_active; then
        echo '{"text": "󰛊", "tooltip": "Caffeine: ON\nIdle inhibited", "class": "active"}'
    else
        echo '{"text": "󰛊", "tooltip": "Caffeine: OFF", "class": "inactive"}'
    fi
}

case "$1" in
    toggle)
        if is_active; then
            stop_caffeine
        else
            start_caffeine
        fi
        pkill -RTMIN+9 waybar
        ;;
    status)
        status
        ;;
    *)
        status
        ;;
esac
