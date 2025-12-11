{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "with-url";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-OFL8MkrVsRbOKs/yOrRQEzoDg7zmJxXgru8WeTq6V3s=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Upload file to cloud storage and execute command with URL";
    license = licenses.mit;
    mainProgram = "with-url";
  };
}
