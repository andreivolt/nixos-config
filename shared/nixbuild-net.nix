{ config, lib, ... }:
let
  allSubstituters = config.nix.settings.substituters;
  # only public caches are reachable from nixbuild.net
  substituters = lib.filter (lib.hasPrefix "https://") allSubstituters;
  keys = lib.unique config.nix.settings.trusted-public-keys;
in {
  nix.buildMachines = [{
    hostName = "eu.nixbuild.net";
    systems = [ "x86_64-linux" "aarch64-linux" ];
    maxJobs = 100;
    supportedFeatures = [ "benchmark" "big-parallel" ];
  }];

  programs.ssh.knownHosts."eu.nixbuild.net" = {
    hostNames = [ "eu.nixbuild.net" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
  };

  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IPQoS throughput
      IdentityFile /home/andrei/.ssh/id_ed25519
      SetEnv NIXBUILDNET_SUBSTITUTERS="${lib.concatStringsSep " " substituters}"
      SetEnv NIXBUILDNET_TRUSTED_PUBLIC_KEYS="${lib.concatStringsSep " " keys}"
  '';
}
