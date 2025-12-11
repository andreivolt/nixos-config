{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "claude-files";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-1a9oXBwrYDnEpSjX2bKITyYc6ItVPvD2v79EBUZBB/I=";

  meta = with lib; {
    description = "List files from Claude Code sessions";
    license = licenses.mit;
    mainProgram = "claude-files";
  };
}
