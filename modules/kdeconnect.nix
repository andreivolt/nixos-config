{ config, lib, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    services.kdeconnect.enable = true;

    home.packages = with pkgs; [ kdeconnect ];
  };

  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
}
