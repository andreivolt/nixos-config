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
  pname = "deepgram-tts";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

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
    description = "Text-to-speech using Deepgram API";
    license = licenses.mit;
    mainProgram = "deepgram-tts";
  };
}
