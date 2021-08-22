{ config, pkgs, ... }:

{
  systemd.user.services.flashfocus = {
    serviceConfig.ExecStart = "${pkgs.flashfocus}/bin/flashfocus --time 250";
    path = with pkgs; [ procps ];

    bindsTo = [ "sway-session.target" ];
    wants = [ "sway-session.target" ];
    wantedBy = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
  };
}

