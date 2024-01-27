{ config, pkgs, ... }:

{
  systemd.user.services.clipman = {
    serviceConfig = {
      # restore last history item at startup
      ExecStartPre = "${pkgs.clipman}/bin/clipman restore";
      # store clipboard history
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store";
    };

    bindsTo = [ "sway-session.target" ];
    wants = [ "sway-session.target" ];
    wantedBy = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
  };

  home-manager.users.andrei.home.packages = with pkgs; [ clipman ];
}

