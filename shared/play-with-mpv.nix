{pkgs, lib, ...}: {
  nixpkgs.config.permittedInsecurePackages = [
    "python3.12-youtube-dl-2021.12.17"
  ];
  home-manager.users.andrei = lib.mkMerge [
    # Linux: systemd service
    (lib.mkIf pkgs.stdenv.isLinux {
      systemd.user.services.play-with-mpv = {
        Unit = {
          PartOf = ["sway-session.target"];
          After = ["sway-session.target"];
        };
        Service.ExecStart = "${pkgs.play-with-mpv}/bin/play-with-mpv";
        Install.WantedBy = ["sway-session.target"];
      };
    })

    # macOS: launchd service
    (lib.mkIf pkgs.stdenv.isDarwin {
      launchd.agents.play-with-mpv = {
        enable = true;
        config = {
          Label = "play-with-mpv";
          ProgramArguments = ["${pkgs.play-with-mpv}/bin/play-with-mpv"];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    })
  ];
}
