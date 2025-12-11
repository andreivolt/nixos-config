{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "json2nix";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-ZsIXo/rCyW3WUlTdhole+x3QGbYL5D/Lciu5yZ5H2r0=";

  meta = with lib; {
    description = "Convert JSON to Nix format";
    license = licenses.mit;
    mainProgram = "json2nix";
  };
}
