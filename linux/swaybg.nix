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
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i /home/andrei/drive/in/macos-wallpapers/monterey.jpg -m fill";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}