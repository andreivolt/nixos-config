{
  # Remote builders configuration
  nix.buildMachines = [{
    hostName = "riva.avolt.net";
    sshUser = "root";
    sshKey = "/var/root/.ssh/id_rsa";
    system = "x86_64-linux";
    maxJobs = 4;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  }];
  nix.distributedBuilds = true;
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';

  # SSH config for nix daemon to use remote builders
  environment.etc."ssh/ssh_config.d/nix-remote-builders".text = ''
    Host riva.avolt.net
        HostName riva.avolt.net
        User root
        IdentityFile /var/root/.ssh/id_rsa
        IdentitiesOnly yes
        StrictHostKeyChecking no
  '';
}
