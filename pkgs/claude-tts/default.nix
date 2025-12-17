{
  lib,
  rustPlatform,
  makeWrapper,
  pkg-config,
  openssl,
  alsa-lib,
  andrei,
}:

rustPlatform.buildRustPackage {
  pname = "claude-tts";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper pkg-config ];

  buildInputs = [ openssl alsa-lib ];

  postInstall = ''
    wrapProgram $out/bin/claude-tts \
      --prefix PATH : ${lib.makeBinPath [
        andrei.deepgram-tts
        andrei.elevenlabs
        andrei.unrealspeech
        andrei.cartesia
      ]}
  '';

  meta = with lib; {
    description = "TTS hook for Claude Code";
    license = licenses.mit;
    mainProgram = "claude-tts";
  };
}
