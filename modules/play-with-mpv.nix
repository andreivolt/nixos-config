{
  home-manager.users.avo = { pkgs, ... }: {
    systemd.user.services.play-with-mpv = {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${pkgs.play-with-mpv}/bin/play-with-mpv";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
