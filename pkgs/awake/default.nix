{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "awake";
  version = "0.1.0";

  src = ./.;

  cargoHash = lib.fakeHash;

  meta = {
    description = "Control KeepingYouAwake on macOS";
    platforms = lib.platforms.darwin;
  };
}
