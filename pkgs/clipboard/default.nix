{
  lib,
  rustPlatform,
  darwin,
  sqlite,
}:
rustPlatform.buildRustPackage {
  pname = "clipboard";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ ];

  buildInputs = [
    darwin.apple_sdk.frameworks.CoreFoundation
    sqlite
  ];

  meta = {
    description = "Browse and manage Maccy clipboard history";
    platforms = lib.platforms.darwin;
  };
}
