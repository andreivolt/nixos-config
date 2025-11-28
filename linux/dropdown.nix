{ config, lib, pkgs, ... }:

let
  terminal = pkgs.kitty;
  # --single-instance keeps one kitty process, --instance-group dropdown ensures dropdown windows share same instance
  terminalCommand = "${terminal}/bin/kitty --single-instance --instance-group dropdown --class dropdown";
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
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}