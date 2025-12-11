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
  pname = "elevenlabs";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-tpgksqXpWWKHIz/eLclcir9McXdpcJu03YJ+hnobRfM=";

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
    description = "Text-to-speech using ElevenLabs API";
    license = licenses.mit;
    mainProgram = "elevenlabs";
  };
}
