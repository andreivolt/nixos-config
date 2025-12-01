{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./headscale.nix
  ];

  # Boot configuration for OCI
  boot.tmp.cleanOnBoot = true;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = false;
  };

  # Use zram for swap (important for 1GB RAM instances)
  zramSwap.enable = true;

  # Networking
  networking = {
    hostName = "oci";
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

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDicuhnKrdUp8G8JZH+jEZWpTTCYO5zQ7I30an07AfS8VP734swtLVc6Hwl5wZ37R8mbusOccw2VsUAZYQBWBZs4tqmzHxAT2fIPo22xgXggdgyb6uXcC7/pvb6BiCkIYawAU3Rbw7Le295HC3g/SkJMlpiKlJllyyzjyP3JISBYKMJdO6PJxsfUHJDG5LCA1/hMyjKjPT5QO6/Go4usEgThcvMxJiV9bVL16PAuENnFLCA3avj9cfk/5VN/HUG1f3SVFQytivFPIb54ke3tgr7Z/a2MZKj+GcTpmxoFLlsmmz6uPSRE+eB8QzpRlO+rny9YmHhKmt10tdEU/KITQAlBLfowE5fJIZIjlui70pWgh62GFDO/30RaJXkUSD8pYUwzzcdAWVbMZsyJ1A7O79deryp8ZFBAUJsiaw2KhCCOLcVFv06n2wUyUZjPE2u1NduWQLZLP/Vnzi1JRYhims8RzN/UyA24uY3XbKZ+jV8kUuoHATiNiI62/CJExABhOk= andrei@mac"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJA4s03JG4C4b9/vd1qB2ZkGzVxuIYSL4cgVUzQ0khzX u0_a779@localhost"
  ];

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

  system.stateVersion = "23.11";
}
