{ config, lib, pkgs, ... }:

let
  kbd-backlight-idle = pkgs.writeShellScript "kbd-backlight-idle" ''
    LED=/sys/class/leds/kbd_backlight/brightness
    TIMEOUT=3
    SAVED=$(cat "$LED")
    USER_DISABLED=/tmp/kbd-backlight-user-disabled

    exec < <(${pkgs.libinput}/bin/libinput debug-events 2>/dev/null | grep --line-buffered KEYBOARD)

    while true; do
      if read -t $TIMEOUT -r _; then
        # Drain all pending events to avoid per-event sysfs reads
        while read -t 0.01 -r _; do :; done

        # Input detected - restore if off AND not user-disabled
        if [ "$(cat "$LED")" = "0" ] && [ "$SAVED" != "0" ]; then
          if [ ! -f "$USER_DISABLED" ]; then
            echo "$SAVED" > "$LED"
          fi
        fi
        cur=$(cat "$LED"); [ "$cur" != "0" ] && SAVED=$cur
      else
        # Timeout - turn off (and clear user-disabled flag so next input restores)
        cur=$(cat "$LED")
        if [ "$cur" != "0" ]; then
          SAVED=$cur
          echo 0 > "$LED"
        fi
        rm -f "$USER_DISABLED"
      fi
    done
  '';
in
{
  systemd.services.kbd-backlight-idle = {
    description = "Keyboard backlight auto-off on idle";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = kbd-backlight-idle;
      Restart = "always";
      RestartSec = 5;
    };
  };

  # Ensure the LED is writable
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="kbd_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/kbd_backlight/brightness"
  '';
}
