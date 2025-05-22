{ inputs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      unstable = inputs.nixpkgs.legacyPackages.${super.system};
    })
  ];
}
