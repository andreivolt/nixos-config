{
  lib,
  rustPlatform,
  pkg-config,
  dbus,
}:
rustPlatform.buildRustPackage {
  pname = "lan-mouse-tray";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  meta = {
    description = "System tray icon for lan-mouse service";
    platforms = lib.platforms.linux;
    mainProgram = "lan-mouse-tray";
  };
}
