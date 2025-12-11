{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "screenshot";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-JrqVzwZfOMyY3T/568a89cV5EiL704YCVPnU+EK0GXM=";

  meta = with lib; {
    description = "Cross-platform screenshot tool";
    license = licenses.mit;
    mainProgram = "screenshot";
  };
}
