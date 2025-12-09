# Linux-specific packages (not available or not needed on Darwin)
pkgs:
with pkgs;
let
  inherit (pkgs.stdenv.hostPlatform) isx86_64;
in
[
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
  pciutils
  psmisc
  strace
  usbutils
  wev
  xdg-user-dirs
  xdg-utils
]
++ lib.optionals isx86_64 [
  boot
  osquery
]
