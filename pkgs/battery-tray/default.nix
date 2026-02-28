{
  lib,
  rustPlatform,
  pkg-config,
  dbus,
  cairo,
  pango,
  glib,
}:
rustPlatform.buildRustPackage {
  pname = "battery-tray";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus cairo pango glib ];

  meta = {
    description = "Battery tray icon with circular progress indicator";
    platforms = lib.platforms.linux;
    mainProgram = "battery-tray";
  };
}
