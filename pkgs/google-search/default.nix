{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "google-search";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-pZm6keZcIJXY7AIJTzChe53/8ubXlt7xTsb23RfGTgI=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Google search via SerpAPI";
    license = licenses.mit;
    mainProgram = "google-search";
  };
}
