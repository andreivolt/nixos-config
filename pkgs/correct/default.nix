{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "correct";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-78YTpjeyNGDemMi8dS5e0ves8CBEPuVdRIxfM8IL7k0=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Fix orthographic and grammatical errors using LLM";
    license = licenses.mit;
    mainProgram = "correct";
  };
}
