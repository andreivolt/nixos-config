{
  lib,
  rustPlatform,
  pkg-config,
  alsa-lib,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "dictate";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-L+A8wLrqLVpL4MRnf+uh+tX0v3Q+AtO+jU0RaDUTArA=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    alsa-lib
    openssl
  ];

  meta = with lib; {
    description = "Voice-to-text dictation using Deepgram";
    license = licenses.mit;
    mainProgram = "dictate";
  };
}
