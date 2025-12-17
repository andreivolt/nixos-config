{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "htmlpaste";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  meta = with lib; {
    description = "Paste HTML from clipboard";
    license = licenses.mit;
    mainProgram = "htmlpaste";
  };
}
