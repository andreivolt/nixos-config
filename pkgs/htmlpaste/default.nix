{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "htmlpaste";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-E7fu4KFiJgFx5ggDv4bdId+piBokwV3ykwbxUQ7yNag=";

  meta = with lib; {
    description = "Paste HTML from clipboard";
    license = licenses.mit;
    mainProgram = "htmlpaste";
  };
}
