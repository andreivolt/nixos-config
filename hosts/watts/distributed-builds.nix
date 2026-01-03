{
  # nix-serve cache for fast LAN access from riva
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/persist/secrets/nix-serve.key";
  };
  networking.firewall.allowedTCPPorts = [ 5000 ];

  # Build on riva for aarch64-linux packages
  nix.buildMachines = [{
    hostName = "riva";
    sshUser = "root";
    sshKey = "/root/.ssh/id_ed25519";
    system = "aarch64-linux";
    maxJobs = 8;
    supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
  }];
}
