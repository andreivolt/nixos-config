{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage {
  pname = "screensaver";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ vulkan-loader wayland libxkbcommon ];

  postFixup = ''
    patchelf --add-rpath ${pkgs.lib.makeLibraryPath [
      pkgs.vulkan-loader
      pkgs.wayland
      pkgs.libxkbcommon
    ]} $out/bin/screensaver
  '';

  meta = with pkgs.lib; {
    description = "Minimal Wayland GLSL screensaver using wgpu";
    license = licenses.mit;
    mainProgram = "screensaver";
  };
}
