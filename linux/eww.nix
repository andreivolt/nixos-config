{ config, lib, pkgs, ... }:

{
  # EWW bar systemd user service
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.eww = {
      Unit = {
        Description = "ElKowars wacky widgets daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
        ExecStartPost = "${pkgs.eww}/bin/eww open bar";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Hyprland listener for eww workspace updates
    systemd.user.services.eww-hyprland-listener = {
      Unit = {
        Description = "EWW Hyprland workspace listener";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" "eww.service" ];
        Requires = [ "eww.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "%h/.config/eww/scripts/hyprland-listener";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
