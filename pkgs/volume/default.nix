{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "volume";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Volume daemon with event batching and wob integration";
    platforms = lib.platforms.linux;
    mainProgram = "volume";
  };
}
