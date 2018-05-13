{ config, pkgs, ... }:

{
  systemd.user.services.qutebrowser = {
    enable = true;
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type      = "forking";
      Restart   = "always";
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '\
          source ${config.system.build.setEnvironment};\
          source ~/.nix-profile/etc/profile.d/hm-session-vars.sh;\
          exec ${pkgs.qutebrowser}/bin/qutebrowser;\
        '
      '';
      PIDFile   = "/run/qutebrowser.pid";
      ExecStop  = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
    };
  };
}
