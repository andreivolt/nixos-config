let ui = import ./ui.nix; fontEnv = {
  LAUNCHER_FONT_SIZE = toString ui.fontSizePx;
  LAUNCHER_FONT_FAMILY = ui.fontFamily;
}; in {
  services.launcher.enable = true;
  systemd.user.services.launcher.environment = fontEnv;
  systemd.user.services.clipboard.environment = fontEnv;
}
