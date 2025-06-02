{lib, pkgs, ...}: {
  # Linux: Use services.tor
  services.tor = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    client.enable = true;
    client.dns.enable = true;
    torsocks.enable = true;
  };

  # macOS: Use homebrew
  homebrew.brews = lib.mkIf pkgs.stdenv.isDarwin [
    {
      name = "tor";
      restart_service = true;
    }
  ];
}
