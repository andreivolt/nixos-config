{ pkgs, ... }:

let
  roon-idle-inhibit = pkgs.callPackage ../../pkgs/roon-idle-inhibit {};
in {
  systemd.services.roon-idle-inhibit = {
    description = "Prevent sleep when Roon is playing";
    after = [ "roon-server.service" ];
    bindsTo = [ "roon-server.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${roon-idle-inhibit}/bin/roon-idle-inhibit";
      Restart = "always";
      RestartSec = 5;
      StateDirectory = "roon-idle-inhibit";
    };
  };
}
