{ config, pkgs, ... }:

{
  home-manager.users.avo.programs.mako = with (import ./theme.nix); {
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
    serviceConfig = {
      ExecStart = "${pkgs.mako}/bin/mako";
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
    };
    wantedBy = [ "sway-session.target" ];
    restartTriggers = [
      config.home-manager.users.avo.xdg.configFile."mako/config".source
    ];
  };
}
