{
  craneLib,
  pkg-config,
  rustPlatform,
  dbus,
  pipewire,
  lib,
}:
craneLib.buildPackage {
  src = craneLib.cleanCargoSource ./.;

  nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook ];
  buildInputs = [ dbus pipewire ];

  meta = {
    description = "macOS-style orange dot tray indicator when microphone is recording";
    platforms = lib.platforms.linux;
    mainProgram = "mic-indicator";
  };
}
