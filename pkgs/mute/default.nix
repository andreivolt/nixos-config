{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  alsa-lib,
  darwin,
}:

rustPlatform.buildRustPackage {
  pname = "mute";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-0/c08xV74Sz7seDoXlfIuPl6X1oyH5e4et4SedyN5Y8=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.AudioToolbox
    darwin.apple_sdk.frameworks.CoreAudio
  ];

  meta = with lib; {
    description = "Mute/unmute the default input device";
    license = licenses.mit;
    mainProgram = "mute";
  };
}
