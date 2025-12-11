{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "pngpaste";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-fO0DqW+PF+MhteGx6+41VLFVb5P/P4/okftwUKmekeA=";

  meta = with lib; {
    description = "Paste PNG image from clipboard";
    license = licenses.mit;
    mainProgram = "pngpaste";
  };
}
