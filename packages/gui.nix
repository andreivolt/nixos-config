pkgs:
let
  inherit (pkgs) lib makeWrapper symlinkJoin;
  inherit (pkgs.stdenv) isLinux isDarwin;
  inherit (pkgs.stdenv.hostPlatform) isAarch64 isx86_64;
in
with pkgs;

[
  neovide
  zed-editor
]
++ lib.optionals isLinux [
  emacs-pgtk
  gcolor3
  lan-mouse
  brightnessctl
  dragon-drop
  ff2mpv
  freerdp
  fswebcam
  grim
  hyprsunset
  imv
  kitty
  liberation_ttf
  libnotify
  libreoffice-fresh
  nerd-fonts.iosevka-term
  pavucontrol
  playerctl
  scrcpy
  slurp
  swayimg
  swaynotificationcenter
  tela-icon-theme
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
  caprine-bin
  discord
  google-chrome
  input-leap
  puppeteer-cli

  slack
  spotify
  tidal-hifi
  vscode
  waynergy
  ytmdesktop
  zoom-us
]
++ lib.optionals isDarwin [
  emacs
  google-chrome
  monitorcontrol
  plistwatch
]
