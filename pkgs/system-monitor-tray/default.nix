{
  lib,
  rustPlatform,
  pkg-config,
  dbus,
}:
rustPlatform.buildRustPackage {
  pname = "system-monitor-tray";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  meta = {
    description = "CPU/memory system tray icon with dual vertical bars";
    platforms = lib.platforms.linux;
    mainProgram = "system-monitor-tray";
  };
}
