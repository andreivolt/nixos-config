pkgs: with pkgs; let
  cached-nix-shell = callPackage ./pkgs/cached-nix-shell { };
  ffsclient = callPackage ./pkgs/ffs_client { };
  googler = callPackage ./pkgs/googler { };
  impbcopy = callPackage ./pkgs/impbcopy { };
  json2nix = callPackage ./pkgs/json2nix { };
  pbpaste-html = callPackage ./pkgs/pbpaste-html { };
  pushover-cli = callPackage ./pkgs/pushover-cli { };
  ruby_3_4 = callPackage ./pkgs/ruby_3_4 { };
  screenshot_tweet = callPackage ./pkgs/screenshot_tweet { };
  ttok = pkgs.python3.pkgs.callPackage ./pkgs/ttok {};
in
[
  (callPackage cached-nix-shell {})
  (ruby_3_4.withPackages (ps: with ps; [ pry pry-byebug pry-doc ]))
  (tmux.overrideAttrs (oldAttrs: rec { version = "3.3a"; src = fetchurl { url = "https://github.com/tmux/tmux/releases/download/${version}/tmux-${version}.tar.gz"; sha256 = "sha256-5P00eEO9B3LE9I1t3mJbCxCbejgP8V2yHpfBGk3N+T8="; }; patches = []; }))
  android-tools
  aria2
  arp-scan
  bat
  bc
  brotab
  btop
  bun
  cargo
  curl
  delta
  deno
  direnv
  discord
  dnsutils
  duf
  edir
  eza
  fastgron
  fd
  ffsclient
  file
  firefox_decrypt
  fzf
  gdrive3
  gh
  git
  git-extras
  git-open
  glab
  glow
  gnupg
  go
  google-chrome
  googler
  grc
  htop-vim
  httpie
  hyperfine
  iftop
  imagemagick
  inetutils
  jo
  jq
  json2nix
  lastpass-cli
  libiconvReal
  lsof
  mediainfo
  moreutilsWithoutParallel
  mosh
  ncdu_1
  neovide
  neovim
  netcat
  nix-index
  nix-prefetch-git
  nixd
  nmap
  nodejs
  nvimpager
  ouch
  pandoc
  parallel
  patchelf
  patchutils
  pdftk
  pkg-config
  pnpm
  pstree
  pushover-cli
  pv
  rclone
  recode
  ripgrep
  rlwrap
  rsync
  screenshot_tweet
  shell-gpt
  socat
  sox
  sqlite
  tcpdump
  telegram-desktop
  terminal-colors
  tidyp
  tmate
  tree
  tree-sitter
  ttok
  unstable.eslint
  uv
  viddy
  vscode
  w3m
  wdiff
  weechat
  wego
  wget
  xdg-utils
  xurls
  yt-dlp
  zathura
  zoom-us
] ++
(lib.optionals stdenv.hostPlatform.isDarwin (with darwin;
  (with darwin.apple_sdk.frameworks; [
    CoreFoundation
    Security
    SystemConfiguration
]) ++
[
  asitop
  coreutils
  duti
  findutils
  gawk
  gnugrep
  gnused
  impbcopy
  iproute2mac
  lsusb
  m-cli
  mas
  pbpaste-html
  plistwatch
  pngpaste
  psutils
  terminal-notifier
  trash
  util-linux
  watch
  xcodes
])) ++
lib.optionals stdenv.hostPlatform.isLinux [
  (mozilla.latest.firefox-nightly-bin.override { cfg.enableFXCastBridge = true; cfg.speechSynthesisSupport = true; })
  acpi
  alsa-utils
  beeper
  binutils
  breeze-gtk
  breeze-qt5
  caprine-bin
  detox
  ffmpeg-full
  fswebcam
  gcolor2
  gnome-epub-thumbnailer
  imv
  inotify-tools
  iotop
  kitty
  libnotify
  libreoffice-fresh
  libsForQt5.breeze-gtk
  libsForQt5.kdegraphics-thumbnailers
  lm_sensors
  lshw
  mpv
  nethogs
  pciutils
  playerctl
  psmisc
  slack
  strace
  sublime4
  swaytools
  tidal-hifi
  trash-cli
  usbutils
  whatsapp-for-linux
  wl-clipboard-x11
  wlprop
  xdg-user-dirs
  xdragon
  ytmdesktop
]
