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
  pname = "gcloudocr";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "OCR using Google Cloud Vision API";
    license = licenses.mit;
    mainProgram = "gcloudocr";
  };
}
