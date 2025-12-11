{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "claude-sessions";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-tNP69I/rRXBmbAnFn/oK/O40KfA8a3yX1rDNDBvihJY=";

  meta = with lib; {
    description = "Browse and search Claude Code sessions";
    license = licenses.mit;
    mainProgram = "claude-sessions";
  };
}
