{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "reddit-comments";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-eEQfURB85HSas/0kIB5FZ11snug9KgSQkuMEMJ1+Ei0=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Fetch and display Reddit comments";
    license = licenses.mit;
    mainProgram = "reddit-comments";
  };
}
