{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "hn-search";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-xwNLzSmK+72TemWzXDn2jcgvmm8cUq8YjqGeoAlm1hU=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Search Hacker News";
    license = licenses.mit;
    mainProgram = "hn-search";
  };
}
