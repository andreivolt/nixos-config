{
  lib,
  rustPlatform,
  pkg-config,
  dbus,
  lan-mouse,
  andrei,
}:
rustPlatform.buildRustPackage {
  pname = "lan-mouse-tray";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  env.ICON_THEME_PATH = "${andrei.phosphor-icon-theme}/share/icons/Phosphor";
  env.LAN_MOUSE_BIN = "${lan-mouse}/bin/lan-mouse";

  meta = {
    description = "System tray icon for lan-mouse service";
    platforms = lib.platforms.linux;
    mainProgram = "lan-mouse-tray";
  };
}
