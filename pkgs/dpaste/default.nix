{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "dpaste";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-03S4RDO7fucgkDFiVx7FG9B6CS7e6KycMjfkXLOKbYM=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Upload text to dpaste.org";
    license = licenses.mit;
    mainProgram = "dpaste";
  };
}
