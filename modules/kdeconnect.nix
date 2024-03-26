{
  home-manager.users.andrei = { pkgs, config, ... }: {
    services.kdeconnect.enable = true;

    home.packages = with pkgs; [ kdeconnect ];
  };

  networking.firewall = {
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };
}
