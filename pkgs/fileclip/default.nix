{
  lib,
  rustPlatform,
  darwin,
}:
rustPlatform.buildRustPackage {
  pname = "fileclip";
  version = "0.1.0";

  src = ./.;

  cargoHash = lib.fakeHash;

  buildInputs = [
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.Foundation
  ];

  meta = {
    description = "Copy file to clipboard";
    platforms = lib.platforms.darwin;
  };
}
