#!/usr/bin/env bash
# Fast volume control with wob - uses cache to avoid slow wpctl queries
# The cache may drift if volume is changed elsewhere, but resyncs on mute toggle

CACHE="/tmp/volume-cache"
WOB_SOCK="$XDG_RUNTIME_DIR/wob.sock"
STEP=5

send_wob() {
    [[ -p "$WOB_SOCK" ]] && echo "$1" > "$WOB_SOCK" &
}

get_cached_volume() {
    if [[ -f "$CACHE" ]]; then
        cat "$CACHE"
    else
        sync_volume
    fi
}

set_cached_volume() {
    echo "$1" > "$CACHE"
}

sync_volume() {
    local vol
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
    set_cached_volume "$vol"
    echo "$vol"
}

case "$1" in
    up)
        vol=$(get_cached_volume)
        new=$((vol + STEP))
        ((new > 100)) && new=100
        set_cached_volume "$new"
        send_wob "$new"
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${STEP}%+" &
        ;;
    down)
        vol=$(get_cached_volume)
        new=$((vol - STEP))
        ((new < 0)) && new=0
        set_cached_volume "$new"
        send_wob "$new"
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%-" &
        ;;
    mute)
        # Sync on mute to correct any drift
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
            send_wob 0
        else
            vol=$(sync_volume)
            send_wob "$vol"
        fi
        ;;
    sync)
        sync_volume
        ;;
    *)
        echo "Usage: $0 up|down|mute|sync"
        exit 1
        ;;
esac
