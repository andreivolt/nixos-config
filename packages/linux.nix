# Linux-specific packages (not available or not needed on Darwin)
pkgs:
with pkgs;
let
  inherit (pkgs.stdenv.hostPlatform) isx86_64;
in
[
  andrei.battery-tray
  andrei.caffeine
  andrei.dictate
  andrei.lan-mouse-toggle
  andrei.screen
  andrei.sysrec
  andrei.volume
  acpi
  alsa-lib.dev
  alsa-utils
  andrei.battery-time
  binutils
  detox
  glib
  inotify-tools
  iotop
  lm_sensors
  lshw
  lsof
  nethogs
  openssl.dev
  parted
  pciutils
  powertop
  psmisc
  strace
  usbutils
  wev
  xdg-user-dirs
  xdg-utils
  zenity
]
++ lib.optionals isx86_64 [
  boot
  osquery
]
