{
  description = "Simple command line tool to record video and audio from any attached capture device";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.callPackage ./default.nix {};
    packages.x86_64-darwin.default = nixpkgs.legacyPackages.x86_64-darwin.callPackage ./default.nix {};
  };
}