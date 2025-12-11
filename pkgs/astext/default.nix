{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "astext";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-L7yaB4cILkcui1tuW91VAIYwbTpcUdD7Hog0IUCX2mI=";

  meta = with lib; {
    description = "Convert files to plain text";
    license = licenses.mit;
    mainProgram = "astext";
  };
}
