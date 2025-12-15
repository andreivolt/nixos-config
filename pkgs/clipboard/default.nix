{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "clipboard";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Browse and manage Maccy clipboard history";
    platforms = lib.platforms.darwin;
  };
}
