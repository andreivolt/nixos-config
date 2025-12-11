{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "tree-render";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-Lw3BwhUmoFtCjD5qjpZff5e4TippEEbcPXeOXMHfb8M=";

  meta = with lib; {
    description = "Render tree structures";
    license = licenses.mit;
    mainProgram = "tree-render";
  };
}
