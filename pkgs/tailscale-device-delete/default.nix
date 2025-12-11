{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "tailscale-device-delete";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-UomU4b3hSxYC7KT3D2jnA0Jr10PyT21v8VX6fvYM6AA=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Delete Tailscale devices";
    license = licenses.mit;
    mainProgram = "tailscale-device-delete";
  };
}
