{ lib, ... }: {
  nix.buildMachines = [{
    hostName = "watts";
    sshUser = "root";
    sshKey = "/root/.ssh/id_ed25519";
    system = "x86_64-linux";
    maxJobs = 4;
    supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
  }];

  # Always use remote builder, never build locally (only 1GB RAM)
  nix.distributedBuilds = true;
  nix.settings.max-jobs = 0;

  # Use watts as binary cache too
  nix.settings = {
    substituters = lib.mkAfter [ "http://watts:5000" ];
    trusted-public-keys = [ "watts:OmUyAQ1/WfpBi9YDKlEG/ZLWhWy4gqweJFtH8zxQGIE=" ];
  };
}
