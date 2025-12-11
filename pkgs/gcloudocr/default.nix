{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "gcloudocr";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-+tQS81NNlwm4hvOrBoxywy3yEZ28s9N5LQBNpxnWw54=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "OCR using Google Cloud Vision API";
    license = licenses.mit;
    mainProgram = "gcloudocr";
  };
}
