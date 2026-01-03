{
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
