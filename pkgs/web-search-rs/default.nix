{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "web-search-rs";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-pbqG08diXVE6UBPqpRaEim5CN6pscPY/XDLvTO8sqOY=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Web search using SerpAPI";
    license = licenses.mit;
    mainProgram = "web-search-rs";
  };
}
