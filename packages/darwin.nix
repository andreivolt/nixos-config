pkgs:
with pkgs; with pkgs.darwin; [
  andrei.awake
  andrei.blackhole-audio
  andrei.cleanup
  andrei.proxy-toggle
  andrei.resolution
  # andrei.shazam  # TODO: pyaudio build fails (missing setuptools in uv2nix)
  # andrei.transcribe-mlx  # TODO: mlx 0.30.0 has no compatible wheel
  asitop
  coreutils
  duti
  findutils
  fswatch
  gawk
  gnugrep
  gnused
  pkgs.iproute2mac
  libiconvReal
  lsusb
  m-cli
  mas
  pstree
  psutils
  terminal-notifier
  trash
  util-linux
  watch
  xcodes
]
