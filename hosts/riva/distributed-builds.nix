{ lib, ... }: {
  # LAN binary caches (watts has higher priority - faster/closer)
  nix.settings = {
    substituters = lib.mkAfter [
      "http://watts:5000?priority=50"
      "http://ampere:5000"
    ];
    trusted-public-keys = [
      "watts:FSqfFsCS8kQ1S38CJeND7hwRgS778f5sM5yy+rdYnN8="
      "ampere:VemsKe9KxjJHofpyUnMnGC9jHo6v49nAlKVQf/1rseI="
    ];
    connect-timeout = 3;
    download-attempts = 1;
  };

  # Build on watts for x86_64-linux packages
  nix.buildMachines = [{
    hostName = "watts";
    sshUser = "root";
    sshKey = "/root/.ssh/id_ed25519";
    system = "x86_64-linux";
    maxJobs = 8;
    supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
  }];
}
