{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  makeWrapper,
  sox,
}:

rustPlatform.buildRustPackage {
  pname = "deepgram-tts";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config makeWrapper ];

  buildInputs = [ openssl ];

  postInstall = ''
    wrapProgram $out/bin/deepgram-tts \
      --prefix PATH : ${lib.makeBinPath [ sox ]}
  '';

  meta = with lib; {
    description = "Text-to-speech using Deepgram API";
    license = licenses.mit;
    mainProgram = "deepgram-tts";
  };
}
