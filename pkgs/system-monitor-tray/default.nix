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
    description = "Dual-bar system tray monitor (cpu-mem / net)";
    platforms = lib.platforms.linux;
    mainProgram = "system-monitor-tray";
  };
}
