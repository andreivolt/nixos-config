{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage {
  pname = "roon-idle-inhibit";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = {
    description = "Prevent idle/sleep when Roon is playing";
    license = lib.licenses.mit;
    mainProgram = "roon-idle-inhibit";
  };
}
