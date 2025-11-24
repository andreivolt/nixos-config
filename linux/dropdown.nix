{ config, lib, pkgs, ... }:

{
  # Install foot package
  environment.systemPackages = [ pkgs.foot ];

  # Dropdown terminal service
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.dropdown = {
      Unit = {
        Description = "Dropdown terminal";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.foot}/bin/footclient --app-id=footclient-dropdown";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}