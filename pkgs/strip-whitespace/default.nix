{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "strip-whitespace";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-IAL6RRICESvN8jHjKSUWQByhwX6v7W9I99tnckRnm3M=";

  meta = with lib; {
    description = "Trim trailing whitespace and empty lines from files";
    license = licenses.mit;
    mainProgram = "strip-whitespace";
  };
}
