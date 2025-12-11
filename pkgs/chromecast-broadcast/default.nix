{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  alsa-lib,
  openssl,
  darwin,
}:

rustPlatform.buildRustPackage {
  pname = "chromecast-broadcast";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-9wowW3ZoOBXawf+uDrS12PNHgEd83NbhNpH1vC4WMcc=";

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
    description = "Broadcast audio to Chromecast devices";
    license = licenses.mit;
    mainProgram = "chromecast-broadcast";
  };
}
