{ config, pkgs, ... }:

{
  home-manager.users.andrei = {
    programs.mako = with (import (dirOf <nixos-config> + /modules/theme.nix)); {
      enable = true;
      width = 800;
      height = 9999;
      backgroundColor = "#000000CC";
      font = "${font.family} 28";
      layer = "overlay";
      borderSize = 1;
      borderColor = "#00ff00";
      margin = "20";
      padding = "20";

      extraConfig = ''
        [app-name=tidal-hifi]
        default-timeout=5000

        [app-name=Spotify]
        default-timeout=5000
      '';
    };

    systemd.user.services.mako = {
      Service = {
        ExecStart = "${pkgs.mako}/bin/mako";
        ExecReload = "${pkgs.mako}/bin/makoctl reload";
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
      };
      Unit = {
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Install.WantedBy = [ "sway-session.target" ];

      # bindsTo = [ "sway-session.target" ];
      # wants = [ "sway-session.target" ];
      # wantedBy = [ "sway-session.target" ];
      # after = [ "sway-session.target" ];
      # restartTriggers = [
      #   config.home-manager.users.andrei.xdg.configFile."mako/config".source
      # ];
    };
  };
}
