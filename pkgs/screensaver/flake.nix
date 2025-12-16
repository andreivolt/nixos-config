{
  description = "Minimal Wayland GLSL screensaver using wgpu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "screensaver-wgpu";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            vulkan-loader
            wayland
            libxkbcommon
          ];

          # Runtime library path for Vulkan
          postFixup = ''
            patchelf --add-rpath ${pkgs.lib.makeLibraryPath [
              pkgs.vulkan-loader
              pkgs.wayland
              pkgs.libxkbcommon
            ]} $out/bin/screensaver-wgpu
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cargo
            rustc
            rust-analyzer
            pkg-config
            vulkan-loader
            wayland
            libxkbcommon
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.vulkan-loader
            pkgs.wayland
            pkgs.libxkbcommon
          ];
        };
      });
}
