pkgs:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv) isLinux isDarwin;
  inherit (pkgs.stdenv.hostPlatform) isAarch64 isx86_64;
in
with pkgs;

# Universal packages (all platforms)
[
  # Development tools (cross-platform)
  age
  android-tools
  ansifilter
  aria2
  arp-scan
  ast-grep
  babashka
  bfg-repo-cleaner
  bun
  cached-nix-shell
  cargo
  catt
  clojure
  clojure-lsp
  cloudflared
  cmake
  csvkit
  curlie
  deno
  diffsitter
  direnv
  dnsutils
  doctl
  dogdns
  duf
  dwdiff
  edir
  erdtree
  eslint
  fastgron
  fdupes
  ff2mpv
  firefox_decrypt
  flyctl
  freerdp
  gdrive3
  geoipWithDatabase
  ghostscript
  git-extras
  git-open
  glab
  glow
  gnupg
  go
  gojq
  google-cloud-sdk
  gum
  htmlq
  hyperfine
  iftop
  imagemagick
  inetutils
  jet
  jo
  json2nix
  jujutsu
  lastpass-cli
  lazydocker
  litecli
  mediainfo
  mitmproxy
  mkcert
  moreutilsWithoutParallel
  neovim-remote
  netcat
  nix-prefetch-git
  nixd
  nixfmt-rfc-style
  nushell
  nvimpager
  oci-cli
  openssl
  ouch
  pandoc
  parallel
  patchelf
  patchutils
  pdftk
  pnpm
  poppler-utils
  portaudio
  procs
  pry
  pv
  redo
  rlwrap
  rubocop
  ruby
  ruby-lsp
  ruff
  rust-script
  rustc
  rustfmt
  scc
  scrcpy
  shell-gpt
  sox
  sqlite
  sqlite-utils
  stack
  stylua
  tabview
  terminal-colors
  tidyp
  timg
  tree-sitter
  trurl
  upterm
  uv
  viddy
  w3m
  wakeonlan
  watchexec
  wdiff
  websocat
  weechat
  xh
  xurls
  yarn-berry
  zprint

  # GUI apps (cross-platform)
  emacs
  gcolor3
  lan-mouse
  neovide
  zed-editor
]

# Linux only (x86 + arm)
++ lib.optionals isLinux [
  # System utilities
  acpi
  detox
  fswebcam
  iotop
  libreoffice-fresh
  nethogs
  dragon-drop
  alejandra
  alsa-utils
  bat
  binutils
  brightnessctl
  btop
  curl
  delta
  eww
  eza
  fd
  ffmpeg-full
  file
  fzf
  gcc
  gh
  git
  glib
  gnumake
  grim
  htop-vim
  hyprsunset
  imv
  swayimg
  inotify-tools
  jq
  kitty
  lazygit
  liberation_ttf
  libnotify
  lm_sensors
  lshw
  lsof
  mosh
  ncdu_1
  neovim
  nerd-fonts.iosevka-term
  nix-top
  nix-index
  nmap
  nodejs
  pavucontrol
  pciutils
  pkg-config
  playerctl
  psmisc
  rclone
  ripgrep
  rsync
  sshpass
  slurp
  socat
  sops
  strace
  tcpdump
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
  tmux
  trash-cli
  tree
  unzip
  usbutils
  wayland-pipewire-idle-inhibit
  wget
  wf-recorder
  wl-clipboard
  wlprop
  wofi
  xdg-user-dirs
  xdg-utils
  yazi
  ydotool
  yt-dlp
  zathura
  sublime4
]

# x86_64-linux only
++ lib.optionals (isLinux && isx86_64) [
  beeper
  boot
  caprine-bin
  discord
  google-chrome
  input-leap
  osquery
  pulumi-bin
  puppeteer-cli

  slack
  spotify
  tidal-hifi
  vscode
  waynergy
  wasistlos
  ytmdesktop
  zoom-us
]

# darwin only
++ lib.optionals isDarwin [
  google-chrome
  iproute2mac
]
++ lib.optionals isDarwin (with darwin; [
  fswatch
  asitop
  coreutils
  duti
  findutils
  gawk
  gnugrep
  gnused
  libiconvReal
  lsusb
  m-cli
  mas
  monitorcontrol
  plistwatch
  psutils
  terminal-notifier
  trash
  util-linux
  watch
  xcodes
])
