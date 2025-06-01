{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.lowbatt;
in {
  options = {
    services.lowbatt = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable low battery suspend.
        '';
      };
      device = mkOption {
        default = "BAT0";
        description = ''
          Device to monitor.
        '';
      };
      notifyCapacity = mkOption {
        default = 10;
        description = ''
          Battery level at which a notification shall be sent.
        '';
      };
      suspendCapacity = mkOption {
        default = 5;
        description = ''
          Battery level at which a suspend unless connected shall be sent.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.timers."lowbatt" = {
      description = "check battery level";
      timerConfig.OnBootSec = "1m";
      timerConfig.OnUnitInactiveSec = "1m";
      timerConfig.Unit = "lowbatt.service";
      wantedBy = ["timers.target"];
    };
    systemd.user.services."lowbatt" = {
      description = "battery level notifier";
      serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.device}/capacity)
        battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.device}/status)

        if [[ $battery_capacity -le ${builtins.toString cfg.notifyCapacity} && $battery_status = "Discharging" ]]; then
            ${pkgs.libnotify}/bin/notify-send --urgency=critical --hint=int:transient:1 --icon=battery_empty "Battery Low" "You should probably plug-in."
        fi

        if [[ $battery_capacity -le ${builtins.toString cfg.suspendCapacity} && $battery_status = "Discharging" ]]; then
            ${pkgs.libnotify}/bin/notify-send --urgency=critical --hint=int:transient:1 --icon=battery_empty "Battery Critically Low" "Computer will suspend in 60 seconds."
            sleep 60s

            battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.device}/status)
            if [[ $battery_status = "Discharging" ]]; then
                systemctl suspend
            fi
        fi
      '';
    };
  };
}
# systemd.timers.suspend-on-low-battery = {
#   wantedBy = [ "multi-user.target" ];
#   timerConfig = {
#     OnUnitActiveSec = "120";
#     OnBootSec= "120";
#   };
# };
# systemd.services.suspend-on-low-battery =
#   let
#     battery-level-sufficient = pkgs.writeShellScriptBin
#       "battery-level-sufficient" ''
#       test "$(cat /sys/class/power_supply/BAT1/status)" != Discharging \
#         || test "$(cat /sys/class/power_supply/BAT1/capacity)" -ge 5
#     '';
#   in
#     {
#       serviceConfig = { Type = "oneshot"; };
#       onFailure = [ "suspend.target" ];
#       script = "${battery-level-sufficient}/bin/battery-level-sufficient";
#     };

