{
  lib,
  rust-bin,
  makeRustPlatform,
  pkg-config,
  openssl,
}:

let
  rustToolchain = rust-bin.stable.latest.default;
  rustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };
in
rustPlatform.buildRustPackage {
  pname = "with-url";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Upload file to cloud storage and execute command with URL";
    license = licenses.mit;
    mainProgram = "with-url";
  };
}
