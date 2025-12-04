{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./headscale.nix
    ../linux/base.nix
  ];

  boot.tmp.cleanOnBoot = true;

  # Use zram for swap (important for 1GB RAM instances)
  zramSwap.enable = true;

  # Networking
  networking = {
    hostName = "ampere";
    domain = "";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP (for ACME)
        443   # HTTPS (Headscale)
      ];
      allowedUDPPorts = [
        3478  # STUN for Headscale
      ];
    };
  };

  # SSH access (override base.nix settings for server)
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
  };

  # Override tailscale for server (no --operator flag)
  services.tailscale.extraUpFlags = lib.mkForce ["--login-server=https://hs.avolt.net"];

  # Override gc for server (more aggressive cleanup)
  nix.gc.options = lib.mkForce "--delete-older-than 7d";

  # ACME for SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "andrei@avolt.net";
  };

  # Home Manager for andrei user (CLI only, no GUI packages)
  home-manager.useGlobalPkgs = true;
  home-manager.users.andrei = {pkgs, ...}: {
    home.stateVersion = "23.11";
    home.enableNixpkgsReleaseCheck = false;

    programs.zsh = {
      enable = true;
      enableCompletion = false;
      initContent = "source ~/.config/zsh/rc.zsh";
    };
  };

  system.stateVersion = "23.11";
}
