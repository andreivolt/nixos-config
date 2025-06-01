{
  # Remote builders configuration
  nix.buildMachines = [{
    hostName = "riva.avolt.net";
    sshUser = "root";
    sshKey = "/Users/andrei/.ssh/id_rsa";
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
        IdentityFile /Users/andrei/.ssh/id_rsa
        IdentitiesOnly yes
        StrictHostKeyChecking yes
  '';

  # Copy known_hosts for host key verification
  system.activationScripts.copySSHKnownHosts.text = ''
    mkdir -p /var/root/.ssh
    cp /Users/andrei/.ssh/known_hosts /var/root/.ssh/known_hosts
    chmod 644 /var/root/.ssh/known_hosts
    chown root:wheel /var/root/.ssh/known_hosts
  '';
}
