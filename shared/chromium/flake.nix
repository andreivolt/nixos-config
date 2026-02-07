{
  description = "Chromium extension packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    ff2mpv.url = "github:andreivolt/ff2mpv";
    ff2mpv.inputs.nixpkgs.follows = "nixpkgs";
    dearrow.url = "github:andreivolt/DeArrow";
  };

  outputs = { nixpkgs, ff2mpv, dearrow, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      packages = forAllSystems (system: {
        ff2mpv = ff2mpv.packages.${system}.default;
        dearrow = dearrow.packages.${system}.default;
      });
    };
}
