{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "tailscale-exit-node";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-/AUmj/jWFenk1WLXgOGVoRKPBp5kueh1FKCgzrtFdew=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Manage Tailscale exit nodes";
    license = licenses.mit;
    mainProgram = "tailscale-exit-node";
  };
}
