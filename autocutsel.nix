{ pkgs, ... }:

{
  systemd.user.services.autocutsel = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "forking";
    script = ''
      ${pkgs.autocutsel}/bin/autocutsel -fork
      ${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY -fork
    '';
  };
}
