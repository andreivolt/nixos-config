{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "awake";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Control KeepingYouAwake on macOS";
    platforms = lib.platforms.darwin;
  };
}
