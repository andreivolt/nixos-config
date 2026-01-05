{ lib, ... }: {
  # nix-serve cache for fast LAN access from riva
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/persist/secrets/nix-serve.key";
  };
  networking.firewall.allowedTCPPorts = [ 5000 ];

  # LAN binary cache from ampere
  nix.settings = {
    substituters = lib.mkAfter [ "http://ampere:5000" ];
    trusted-public-keys = [ "ampere:VemsKe9KxjJHofpyUnMnGC9jHo6v49nAlKVQf/1rseI=" ];
  };

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
