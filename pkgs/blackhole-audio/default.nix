{
  lib,
  rustPlatform,
  darwin,
}:
rustPlatform.buildRustPackage {
  pname = "blackhole-audio";
  version = "0.1.0";

  src = ./.;

  cargoHash = lib.fakeHash;

  buildInputs = [
    darwin.apple_sdk.frameworks.CoreAudio
    darwin.apple_sdk.frameworks.AudioToolbox
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = {
    description = "Route audio through BlackHole";
    platforms = lib.platforms.darwin;
  };
}
