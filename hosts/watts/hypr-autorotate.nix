# Auto-rotation for Hyprland tablet mode
# Separate from touchscreen.nix for independent enable/disable
{
  pkgs,
  lib,
  ...
}: {
  home-manager.users.andrei = { config, pkgs, ... }: {
    # Auto-rotation script using iio-sensor-proxy D-Bus events (no polling)
    home.file.".local/bin/hypr-autorotate" = {
      executable = true;
      source = ./hypr-autorotate.sh;
    };

    # Systemd user service for auto-rotation
    systemd.user.services.hypr-autorotate = {
      Unit = {
        Description = "Hyprland auto-rotation for tablet mode";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "%h/.local/bin/hypr-autorotate";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
