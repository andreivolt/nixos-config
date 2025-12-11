{
  lib,
  rustPlatform,
  darwin,
}:
rustPlatform.buildRustPackage {
  pname = "vision";
  version = "0.1.0";

  src = ./.;

  cargoHash = lib.fakeHash;

  buildInputs = [
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.Foundation
    darwin.apple_sdk.frameworks.Vision
    darwin.apple_sdk.frameworks.CoreImage
  ];

  meta = {
    description = "Extract text from images using macOS Vision framework";
    platforms = lib.platforms.darwin;
  };
}
