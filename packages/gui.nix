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
  swaynotificationcenter
  wasistlos
  wayland-pipewire-idle-inhibit
  wf-recorder
  wl-clipboard
  wlprop
  wtype
  sublime4
]
++ lib.optionals (isLinux && isx86_64) [
  beeper
  input-leap
  puppeteer-cli
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
