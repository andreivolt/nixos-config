pkgs:
let
  inherit (pkgs) lib makeWrapper symlinkJoin;
  inherit (pkgs.stdenv) isLinux isDarwin;
  inherit (pkgs.stdenv.hostPlatform) isAarch64 isx86_64;
in
with pkgs;

# GUI apps (cross-platform)
[
  emacs
  gcolor3
  lan-mouse
  neovide
  zed-editor
]

# Linux GUI only
++ lib.optionals isLinux [
  brightnessctl
  dragon-drop
  eww
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
  wofi
  wtype
  zathura
  sublime4
]

# x86_64-linux GUI only
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

# darwin GUI only
++ lib.optionals isDarwin [
  google-chrome
  monitorcontrol
  plistwatch
]
