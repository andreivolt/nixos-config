{ config, pkgs, ... }:

{
  home-manager.users.avo = {
    programs.mako = with (import (dirOf <nixos-config> + /modules/theme.nix)); {
      enable = true;
      width = 500;
      backgroundColor = "#00000050";
      font = "${font.family} 16";
      layer = "overlay";
      borderSize = 0;
      margin = "20";
      padding = "20";
    };

    systemd.user.services.mako = {
      Service = {
        ExecStart = "${pkgs.mako}/bin/mako";
        ExecReload = "${pkgs.mako}/bin/makoctl reload";
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
      };
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Install.WantedBy = [ "graphical-session.target" ];

      # bindsTo = [ "sway-session.target" ];
      # wants = [ "sway-session.target" ];
      # wantedBy = [ "sway-session.target" ];
      # after = [ "sway-session.target" ];
      # restartTriggers = [
      #   config.home-manager.users.avo.xdg.configFile."mako/config".source
      # ];
    };
  };
}
