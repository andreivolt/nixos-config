#!/usr/bin/env bash
# Brightness control with DPMS support and wob OSD
#
# Backlight zones (Apple Silicon, max=509):
#   raw 0:    dimmest visible level; pressing down triggers DPMS off
#   raw 1-2:  dead zone (visually identical to 0, skipped in both directions)
#   raw 3+:   normal range with perceptual (exponential) steps
#
# DPMS wake: Hyprland auto-wakes DPMS on keypress before our script runs,
# so we can't detect "was DPMS off". Instead, DPMS-off sets raw to 0.
# First up from raw 0 sets raw 1 (same visual = dim level shown).
# Second up sees raw<3 and jumps to 3 (first distinct brightness).

WOB_SOCK="$XDG_RUNTIME_DIR/wob.sock"
DDC_BUS_CACHE="/tmp/ddc-bus"
DDC_BRIGHTNESS_CACHE="/tmp/ddc-brightness"
DDC_LOCK="/tmp/ddc-lock"
DDC_STEP=5
DEAD_ZONE_END=3  # first raw value visually distinct from 0

BRIGHTNESS_LEVELS=(0 1 2 4 6 8 10 12 14 16 18 21 23 25 27 29 31 33 35 68 100)

acquire_ddc_lock() {
    exec 9>"$DDC_LOCK"
    flock -n 9 || return 1
}

send_wob() {
    [[ -p "$WOB_SOCK" ]] && echo "$1" > "$WOB_SOCK" &
}

has_backlight() {
    brightnessctl -l 2>/dev/null | grep -q "backlight"
}

get_backlight_percent() {
    brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%'
}

get_backlight_raw() {
    brightnessctl g 2>/dev/null
}

get_ddc_bus() {
    if [[ -f "$DDC_BUS_CACHE" ]]; then
        cat "$DDC_BUS_CACHE"
        return
    fi
    local bus
    bus=$(ddcutil detect --brief 2>/dev/null | grep -A1 '^Display ' | grep -oP '/dev/i2c-\K\d+' | head -1)
    if [[ -n "$bus" ]]; then
        echo "$bus" > "$DDC_BUS_CACHE"
        echo "$bus"
    fi
}

get_ddc_brightness() {
    if [[ -f "$DDC_BRIGHTNESS_CACHE" ]]; then
        cat "$DDC_BRIGHTNESS_CACHE"
        return
    fi
    echo "50" > "$DDC_BRIGHTNESS_CACHE"
    echo "50"
}

set_ddc_brightness() {
    local percent=$1
    local bus ddc_value
    bus=$(get_ddc_bus)
    [[ -z "$bus" ]] && return 1

    ((percent < 0)) && percent=0
    ((percent > 100)) && percent=100

    ddc_value=${BRIGHTNESS_LEVELS[$((percent / 5))]}
    ddcutil --bus="$bus" --skip-ddc-checks --noverify setvcp 10 "$ddc_value" &>/dev/null &

    echo "$percent" > "$DDC_BRIGHTNESS_CACHE"
    echo "$percent"
}

MONITOR_INFO=$(hyprctl monitors -j)
FOCUSED_MONITOR=$(echo "$MONITOR_INFO" | jq -r '.[] | select(.focused == true) | .name')
USE_BACKLIGHT=$([[ "$FOCUSED_MONITOR" == eDP* ]] && has_backlight && echo 1)

case "$1" in
    up)
        if [[ -n "$USE_BACKLIGHT" ]]; then
            raw=$(get_backlight_raw)
            if ((raw == 0)); then
                brightnessctl -q s 1  # mark dim level as visited
            elif ((raw < DEAD_ZONE_END)); then
                brightnessctl -q s "$DEAD_ZONE_END"
            else
                brightnessctl -e -q s 1%+
            fi
            send_wob "$(get_backlight_percent)"
        else
            acquire_ddc_lock || exit 0
            current=$(get_ddc_brightness)
            [[ -z "$current" ]] && exit 1
            result=$(set_ddc_brightness $((current + DDC_STEP)))
            send_wob "$result"
        fi
        ;;

    down)
        if [[ -n "$USE_BACKLIGHT" ]]; then
            raw=$(get_backlight_raw)
            if ((raw <= 1)); then
                brightnessctl -q s 0
                { sleep 0.2 && hyprctl dispatch dpms off; } &
            elif ((raw <= DEAD_ZONE_END)); then
                brightnessctl -q s 0
                send_wob 0
            else
                brightnessctl -e -q s 1%-
                new=$(get_backlight_raw)
                ((new > 0 && new < DEAD_ZONE_END)) && brightnessctl -q s "$DEAD_ZONE_END"
                send_wob "$(get_backlight_percent)"
            fi
        else
            acquire_ddc_lock || exit 0
            current=$(get_ddc_brightness)
            [[ -z "$current" ]] && exit 1
            new=$((current - DDC_STEP))
            ((new < 0)) && new=0
            result=$(set_ddc_brightness "$new")
            send_wob "$result"
        fi
        ;;

    *)
        echo "Usage: $0 up|down"
        exit 1
        ;;
esac
