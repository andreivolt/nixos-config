{ config, lib, pkgs, ... }:

{
  # Install swaybg package
  environment.systemPackages = [ pkgs.swaybg ];

  # Swaybg wallpaper service for user andrei
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.swaybg = {
      Unit = {
        Description = "Wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.swaybg}/bin/swaybg -c '#000000'";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}