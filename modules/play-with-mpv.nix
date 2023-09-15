{ pkgs, ...}:

{
  home-manager.users.avo = { pkgs, ... }: {
    systemd.user.services.play-with-mpv = {
      Unit = {
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
      };
      Service.ExecStart = "${pkgs.play-with-mpv}/bin/play-with-mpv";
      Install.WantedBy = [ "sway-session.target" ];
    };
  };

  environment.systemPackages = [ pkgs.mpv ];

  # programs.chromium = {
  #   enable = true;
  #   extensions = [ "hahklcmnfgffdlchjigehabfbiigleji" ];
  # };
}
