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
  pname = "deepgram";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-sfOdF23NTDqbd+AAX3LyFqtHN7wYNqSfKST/H08091g=";

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
    description = "Audio transcription using Deepgram API";
    license = licenses.mit;
    mainProgram = "deepgram";
  };
}
