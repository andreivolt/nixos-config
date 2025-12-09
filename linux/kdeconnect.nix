{ config, lib, pkgs, ... }:

{
  # Enable KDE Connect with firewall rules
  programs.kdeconnect.enable = true;

  # KDE Connect indicator service via home-manager
  home-manager.users.andrei = { config, pkgs, ... }: {
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };

  # Open firewall on Tailscale interface for cross-network pairing
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };
}
