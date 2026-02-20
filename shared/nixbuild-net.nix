{
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
      SetEnv NIXBUILDNET_SUBSTITUTERS="https://cache.nixos.org https://nix-community.cachix.org https://hyprland.cachix.org https://nixos-apple-silicon.cachix.org"
      SetEnv NIXBUILDNET_TRUSTED_PUBLIC_KEYS="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc= nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
  '';
}
