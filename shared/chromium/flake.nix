{
  description = "Chromium extension packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    ff2mpv.url = "git+file:/home/andrei/dev/ff2mpv";
    dearrow.url = "git+file:/home/andrei/dev/DeArrow";
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
