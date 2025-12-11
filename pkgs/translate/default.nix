{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "translate";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-jn/C1pVP4yLRtpFXmDpE01E8vL3QqehUfuGjoVb6K78=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Translate text using LLM";
    license = licenses.mit;
    mainProgram = "translate";
  };
}
