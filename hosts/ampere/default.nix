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
    ./livekit.nix
    ../../profiles/core.nix
    ../../linux/zram.nix
  ];

  boot.tmp.cleanOnBoot = true;

  # Networking - simple DHCP for server (no NetworkManager)
  networking = {
    hostName = "ampere";
    domain = "";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP (for ACME)
        443   # HTTPS (Headscale)
        5000  # nix-serve binary cache
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

  # Binary cache for watts/riva
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/etc/nix-serve/cache-priv-key.pem";
  };

  # Trust andrei for remote deployments (accept unsigned paths from nix-copy-closure)
  nix.settings.trusted-users = ["root" "andrei"];

  # Override password file path (no /persist on this host)
  users.users.andrei.hashedPasswordFile = lib.mkForce "/etc/passwords/andrei";

  # Sops config (no /persist on this host, secrets per-module)
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

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
  };

  system.stateVersion = "23.11";
}
