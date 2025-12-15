{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "resolution";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Change display resolution";
    platforms = lib.platforms.darwin;
  };
}
