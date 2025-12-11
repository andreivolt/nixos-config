{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "claude-messages";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-0CyYETCjteEyRzTOIpRV0hVOnjpymvxfvUPDGgndFyk=";

  meta = with lib; {
    description = "Search and display Claude Code messages";
    license = licenses.mit;
    mainProgram = "claude-messages";
  };
}
