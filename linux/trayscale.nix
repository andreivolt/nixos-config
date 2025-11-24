{ config, lib, pkgs, ... }:

{
  # Install trayscale package
  environment.systemPackages = lib.mkIf (config.services.tailscale.enable or false) [ pkgs.trayscale ];

  # Trayscale - Tailscale tray icon
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.trayscale = lib.mkIf (config.services.tailscale.enable or false) {
      Unit = {
        Description = "Trayscale system tray applet for Tailscale";
        Documentation = "https://github.com/DeedleFake/trayscale";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" "waybar.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.trayscale}/bin/trayscale";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}