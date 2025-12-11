{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "ocr";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-pdtv1cfWR6ofxIM3eMC95SlKp1Oz0j6uVBesOBz5t24=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "OCR using LLM vision";
    license = licenses.mit;
    mainProgram = "ocr";
  };
}
