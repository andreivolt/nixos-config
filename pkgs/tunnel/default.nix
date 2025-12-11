{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "tunnel";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-pf+TNxAtDckAM9oD5H66hX88FNTNqt12pkk9i12Po2E=";

  meta = with lib; {
    description = "Create SSH tunnels for port forwarding";
    license = licenses.mit;
    mainProgram = "tunnel";
  };
}
