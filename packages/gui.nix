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
  pavucontrol
  playerctl
  scrcpy
  slurp
  swayimg
  swaynotificationcenter
  telegram-desktop
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
  google-chrome
  monitorcontrol
  plistwatch
]
