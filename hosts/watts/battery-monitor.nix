{ config, lib, pkgs, ... }:

{
  # Battery monitor service (custom script)
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.battery-monitor = lib.mkIf (builtins.pathExists "/home/andrei/.local/bin/battery-monitor.sh") {
      Unit = {
        Description = "Battery Monitor for notifications and auto-hibernate";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "%h/.local/bin/battery-monitor.sh";
        Restart = "on-failure";
        Environment = "DISPLAY=:0";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}