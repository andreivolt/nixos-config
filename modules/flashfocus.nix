{ config, pkgs, ... }:

{
  home-manager.users.andrei = { pkgs, ...}: {
    home.packages = with pkgs; [ flashfocus ];
  };

  systemd.user.services.flashfocus = {
    serviceConfig.ExecStart = "${pkgs.flashfocus}/bin/flashfocus --time 250";
    path = with pkgs; [ procps ];

    bindsTo = [ "sway-session.target" ];
    wants = [ "sway-session.target" ];
    wantedBy = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
  };
}

