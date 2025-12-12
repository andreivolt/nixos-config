{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "zsh-history-search";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-Dy3vn+QprZicFUHlN0vus34bvwXjCxHsVTBzjqlwUpM=";

  meta = with lib; {
    description = "Fuzzy search through zsh history with dates";
    license = licenses.mit;
    mainProgram = "zsh-history-search";
  };
}
