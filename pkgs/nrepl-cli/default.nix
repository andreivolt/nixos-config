{ rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "nrepl-cli";
  version = "0.1.0";

  src = ./src;

  cargoLock.lockFile = ./src/Cargo.lock;

  meta = {
    description = "nREPL client with Unix socket support";
  };
}
