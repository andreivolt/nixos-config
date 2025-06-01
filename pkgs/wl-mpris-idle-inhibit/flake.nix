{
  description = "Wayland idle inhibitor for MPRIS media players";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.callPackage ./default.nix {};
    packages.aarch64-linux.default = nixpkgs.legacyPackages.aarch64-linux.callPackage ./default.nix {};
  };
}