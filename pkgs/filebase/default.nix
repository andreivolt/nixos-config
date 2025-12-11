{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  python3,
  xorg,
}:

rustPlatform.buildRustPackage {
  pname = "filebase";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-66BPcdbM2Us86Nb8z7rE3/xsXG9UTTY6Os5Noj0+MTQ=";

  nativeBuildInputs = [ pkg-config python3 ];
  buildInputs = [ openssl xorg.libxcb ];

  meta = with lib; {
    description = "Upload files to Filebase storage service";
    license = licenses.mit;
    mainProgram = "filebase";
  };
}
