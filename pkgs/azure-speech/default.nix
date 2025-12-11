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
  pname = "azure-speech";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-C5Ie3zYRtAVMsoYZR46i1ncnTEZlkT4Z4FVm8PAb55k=";

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
    description = "Text-to-speech using Azure Speech API";
    license = licenses.mit;
    mainProgram = "azure-speech";
  };
}
