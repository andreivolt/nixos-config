{
  description = "Tool for deploying static websites to IPFS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.callPackage ./default.nix {};
    packages.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.callPackage ./default.nix {};
    packages.x86_64-darwin.default = nixpkgs.legacyPackages.x86_64-darwin.callPackage ./default.nix {};
    packages.aarch64-linux.default = nixpkgs.legacyPackages.aarch64-linux.callPackage ./default.nix {};
  };
}