{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  openssl,
  alsa-lib,
  darwin,
}:

rustPlatform.buildRustPackage {
  pname = "unrealspeech";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-aJA6GDTuNEXj5qbyF5sTosw2HDHr8cZ3EI+jL5s3NF0=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    openssl
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.AudioUnit
    darwin.apple_sdk.frameworks.CoreAudio
  ];

  meta = with lib; {
    description = "Text-to-speech using UnrealSpeech API";
    license = licenses.mit;
    mainProgram = "unrealspeech";
  };
}
