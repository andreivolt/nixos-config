{
  lib,
  rustPlatform,
  pkg-config,
  dbus,
}:
rustPlatform.buildRustPackage {
  pname = "mic-indicator";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  meta = {
    description = "macOS-style orange dot tray indicator when microphone is recording";
    platforms = lib.platforms.linux;
    mainProgram = "mic-indicator";
  };
}
