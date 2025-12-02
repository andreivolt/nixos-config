{ config, lib, pkgs, ... }:

let
  kbd-backlight-idle = pkgs.writeShellScript "kbd-backlight-idle" ''
    LED=/sys/class/leds/kbd_backlight/brightness
    TIMEOUT=3
    SAVED=$(cat "$LED")

    exec < <(${pkgs.libinput}/bin/libinput debug-events 2>/dev/null)

    while true; do
      if read -t $TIMEOUT -r _; then
        # Input - restore if off
        [ "$(cat "$LED")" = "0" ] && [ "$SAVED" != "0" ] && echo "$SAVED" > "$LED"
        cur=$(cat "$LED"); [ "$cur" != "0" ] && SAVED=$cur
      else
        # Timeout - turn off
        cur=$(cat "$LED"); [ "$cur" != "0" ] && SAVED=$cur && echo 0 > "$LED"
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
