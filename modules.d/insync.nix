{ pkgs, ... }:

{
  systemd.user.services.insync = {
    after = [ "network.target" ]; wantedBy = [ "default.target" ];
    path = [ pkgs.insync ];
    script = "insync start";
    serviceConfig.Type = "forking";
    serviceConfig.Restart = "always"; };
}
