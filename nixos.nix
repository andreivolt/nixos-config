rec {
  nix = {
    buildCores = 0;
    gc.automatic = true;
    optimise.automatic = true;
  };

  system.autoUpgrade = { enable = true; channel = "https://nixos.org/channels/nixos-unstable"; };


  nixpkgs.overlays = import ./overlays.nix;

  nixpkgs.config.allowUnfree = true;
  home-manager.users.avo.nixpkgs.config = nixpkgs.config;
}
