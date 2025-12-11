{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "claude-command-monitor";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-gZhRFzmaSlMxNCQ59Pqk69SkTijqOleqeOn19Dze7vc=";

  meta = with lib; {
    description = "Monitor Claude Code command events";
    license = licenses.mit;
    mainProgram = "claude-command-monitor";
  };
}
