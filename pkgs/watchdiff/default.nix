{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "watchdiff";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-E/KuIgTV78sLLY/CkO0uIzv3HHq41y0kQG/d/Lu4Chw=";

  meta = with lib; {
    description = "Watch files and show diffs on changes";
    license = licenses.mit;
    mainProgram = "watchdiff";
  };
}
