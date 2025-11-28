{ config, lib, pkgs, ... }:

let
  terminal = pkgs.kitty;
  terminalCommand = "${terminal}/bin/kitty --class dropdown";
in {
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
        ExecStart = terminalCommand;
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}