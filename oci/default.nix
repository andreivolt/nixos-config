{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./headscale.nix
    ../shared/ssh.nix
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

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # andrei user (same as other machines)
  users.users.andrei = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Basic packages
  environment.systemPackages = with pkgs; [
    neovim
    tmux
    htop
    curl
    jq
  ];

  # Automatic garbage collection to save disk space
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # ACME for SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "andrei@avolt.net";
  };

  # Tailscale client to join the network
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--login-server=https://hs.avolt.net"];
  };

  system.stateVersion = "23.11";
}
