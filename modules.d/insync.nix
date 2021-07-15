{ pkgs, ... }:

{
  systemd.user.services.insync = {
    after = [ "network.target" ]; wantedBy = [ "default.target" ];
    script = "${pkgs.insync}/bin/insync start";
    serviceConfig = { Type = "forking"; Restart = "always"; };
  };
}
