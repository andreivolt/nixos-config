{ config, pkgs, ... }:

{
  home-manager.users.avo.systemd.user = {
    sockets.wob = {
      Socket = {
        ListenFIFO = "%t/wob.sock";
        SocketMode = "0600";
      };
      Install.WantedBy = [ "sockets.target" ];
    };

    services.wob = {
      Service = {
        ExecStart = "${pkgs.wob}/bin/wob";
        StandardInput = "socket";
      };
      Unit = {
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Install.WantedBy = [ "sway-session.target" ];
    };
  };
}

