{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "clipboard";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-/D1nRK8vduyZunvO6tR08b/KuRu63S8qA4OUr5Ym8rU=";

  meta = {
    description = "Browse and manage Maccy clipboard history";
    platforms = lib.platforms.darwin;
  };
}
