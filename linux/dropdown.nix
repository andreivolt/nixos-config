{ config, lib, pkgs, ... }:

let
  terminal = pkgs.kitty;
  tmux = pkgs.tmux;

  # Script to attach to dropdown tmux session (create if not exists)
  # -A flag attaches to existing or creates new session
  # Hide status bar inline
  dropdownScript = pkgs.writeShellScript "dropdown-terminal" ''
    exec ${terminal}/bin/kitty --class dropdown ${tmux}/bin/tmux new-session -A -s dropdown \; set -g status off
  '';
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
        ExecStart = "${dropdownScript}";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}