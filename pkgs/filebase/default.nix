{
  lib,
  stdenv,
  rust-bin,
  makeRustPlatform,
  pkg-config,
  openssl,
  python3,
  xorg,
}:

let
  rustToolchain = rust-bin.stable.latest.default;
  rustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };
in
rustPlatform.buildRustPackage {
  pname = "filebase";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config python3 ];
  buildInputs = [ openssl ] ++ lib.optionals stdenv.hostPlatform.isLinux [ xorg.libxcb ];

  meta = with lib; {
    description = "Upload files to Filebase storage service";
    license = licenses.mit;
    mainProgram = "filebase";
  };
}
