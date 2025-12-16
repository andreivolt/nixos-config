{ config, lib, pkgs, ... }:

let
  dropdownScript = pkgs.writeShellScript "dropdown-terminal" ''
    exec ${pkgs.kitty}/bin/kitty --class dropdown ${pkgs.tmux}/bin/tmux new-session -A -s dropdown \; set status off
  '';
in {
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.dropdown = {
      Unit = {
        Description = "Dropdown terminal";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${dropdownScript}";
        Restart = "always";
        RestartSec = 1;
        Environment = [ "TERM=xterm-kitty" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}