pkgs:
let
  inherit (pkgs) lib makeWrapper symlinkJoin;
  inherit (pkgs.stdenv) isLinux isDarwin;
  inherit (pkgs.stdenv.hostPlatform) isAarch64 isx86_64;
in
with pkgs;

[
  ff2mpv
  neovide
  zed-editor
]
++ lib.optionals isLinux [
  emacs-pgtk
  gcolor3
  glslviewer
  lan-mouse
  brightnessctl
  dragon-drop
  freerdp
  fswebcam
  grim
  imv
  kitty
  liberation_ttf
  libnotify
  libreoffice-fresh
  pavucontrol
  playerctl
  scrcpy
  slurp
  swayimg
  swaynotificationcenter
  (symlinkJoin {
    name = "telegram-desktop-wrapped";
    paths = [telegram-desktop];
    nativeBuildInputs = [makeWrapper];
    postBuild = ''
      rm $out/bin/Telegram
      makeWrapper ${telegram-desktop}/bin/Telegram $out/bin/Telegram \
        --set QT_QPA_PLATFORMTHEME xdgdesktopportal
      ln -sf $out/bin/Telegram $out/bin/telegram-desktop
    '';
  })
  wasistlos
  wayland-pipewire-idle-inhibit
  wf-recorder
  wl-clipboard
  wlprop
  rofi
  wtype
  zathura
  sublime4
]
++ lib.optionals (isLinux && isx86_64) [
  beeper
  discord
  google-chrome
  input-leap
  puppeteer-cli

  slack
  spotify
  vscode
  waynergy
  ytmdesktop
  zoom-us
]
++ lib.optionals isDarwin [
  emacs
  monitorcontrol
  plistwatch
]
