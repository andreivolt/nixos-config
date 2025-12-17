{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage {
  pname = "pushover";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [pkg-config];
  buildInputs = [openssl];

  meta = {
    description = "CLI for Pushover notifications";
    license = lib.licenses.mit;
    mainProgram = "pushover";
  };
}
