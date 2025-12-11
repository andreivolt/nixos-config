{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "lifx";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-AZe2XneeLzWkYYEFMFbp2cezTfO0DNJ/UYqhqRMA3mM=";

  meta = with lib; {
    description = "Control LIFX smart lights";
    license = licenses.mit;
    mainProgram = "lifx";
  };
}
