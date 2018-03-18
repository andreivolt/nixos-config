{ pkgs, ... }:

{
  systemd.user.services.autocutsel = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "forking";
    path = with pkgs; [ autocutsel ];
    script = ''
      ${pkgs.autocutsel}/bin/autocutsel -fork
      ${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY -fork
    '';
  };
}
