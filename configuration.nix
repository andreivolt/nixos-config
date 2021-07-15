{ lib, pkgs, ... }:

let
  theme = import ./modules.d/theme.nix;

  packages = let
    moreutilsWithoutParallel = lib.overrideDerivation pkgs.moreutils (attrs: {
      postInstall =
        attrs.postInstall + "\n" +
        "rm $out/bin/parallel $out/share/man/man1/parallel.1";
    });
  in with pkgs; [
    # chromium
    # kotakogram-desktop
    # libreoffice-fresh
    # torbrowser
    (callPackage ./packages/colorpicker.nix {})
    (callPackage ./packages/pushover.nix {})
    (callPackage ./packages/zprint.nix {})
    acpi
    alacritty
    aria
    babashka
    bat
    bc
    chromedriver
    clipman
    clojure
    curl
    dnsutils
    dtach
    dtrx
    ffmpeg-full # -full for ffplay
    file
    firefox
    fzf
    geoip
    gh
    gist
    git
    git-hub
    glpaper
    gnumake
    gnupg
    google-chrome
    graphicsmagick
    httpie
    iftop
    imv
    insync
    iotop
    jq
    kdeconnect
    lastpass-cli
    libarchive # bsdtar
    libnotify
    lsof
    mediainfo
    moreutilsWithoutParallel
    mosh
    mpv
    msmtp
    mupdf
    netcat
    nethogs
    nmap
    nodePackages.peerflix
    nodePackages.webtorrent-cli
    openssl
    pamixer
    pandoc
    parallel
    patchelf
    pavucontrol
    protonvpn-cli
    psmisc
    pup
    python3
    qemu
    recode
    ripgrep
    rlwrap
    socat
    sox
    spotify
    strace
    sublime3
    surf
    t
    tdesktop
    telnet
    tmate
    tree
    ungoogled-chromium
    unzip
    usbutils
    vlc
    wf-recorder
    wget
    xdg_utils
    xfce.thunar
    xurls
    xxd
    youtube-dl
    youtube-viewer
  ];

in {
  imports = [
    ./hardware-configuration.nix
    (import "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos")

    ./modules.d/ad-hosts-block.nix
    ./modules.d/adb.nix
    ./modules.d/hardware-video-acceleration.nix
    ./modules.d/alacritty/alacritty.nix
    ./modules.d/audio.nix
    ./modules.d/cloudflare-dns.nix
    ./modules.d/docker.nix
    ./modules.d/firefox.nix
    ./modules.d/fonts.nix
    ./modules.d/fzf.nix
    ./modules.d/insync.nix
    ./modules.d/kdeconnect.nix
    ./modules.d/low-bat-suspend.nix
    ./modules.d/map-test-tld-to-localhost.nix
    ./modules.d/npm.nix
    ./modules.d/sway.nix
    ./modules.d/tor.nix
    ./modules.d/vim.nix
    ./modules.d/git.nix
    ./modules.d/ripgrep.nix
    # ./modules.d/curl.nix
  ];

  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = https://nixos.org/channels/nixos-unstable;
  system.stateVersion = "19.09";

  services.devmon.enable = true; # automount removable devices

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "fr";

  console.font = "latarcyrheb-sun32"; # hidpi in console

  time.timeZone = "Europe/Paris";

  hardware.bluetooth.enable = true;

  hardware.opengl.enable = true;

  nix.buildCores = 0;
  nix.gc.automatic = true;
  nix.optimise.automatic = true;
  nix.useSandbox = false;

  users.users.avo.isNormalUser = true;
  users.users.avo.shell = pkgs.zsh;
  users.users.avo.extraGroups = [ "wheel" ];

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = builtins.getEnv "HOSTNAME";

  networking.enableIPv6 = false;

  networking.networkmanager.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.variables.GREP_COLOR = "1";

  environment.variables.LESS = ''
    --RAW-CONTROL-CHARS \
    --ignore-case \
    --no-init \
    --quit-if-one-screen\
  '';

  environment.variables.LS_COLORS = "di=0;35:fi=0;37:ex=0;96:ln=0;37";

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  home-manager.users.avo = { pkgs, config, ... }: {
    gtk.enable = true;
    gtk.theme.name = "dark";

    # gtk.theme.package = pkgs.gnome-breeze;

    gtk.font.name = "Source Sans Pro 8";

    home.sessionPath = [ "$HOME/.local/bin" ];

    home.sessionVariables.BROWSER = "google-chrome-stable";
    home.sessionVariables.EDITOR = "vim";
    home.sessionVariables.PAGER = "less";

    home.packages = packages;

    programs.direnv.enable = true;
    programs.direnv.enableZshIntegration = true;

    programs.zsh.shellAliases.ls = ''
      LC_COLLATE=C \
        ls \
          --dereference \
          --human-readable \
          --indicator-style=slash \
    '';
    programs.zsh.shellAliases.l = "ls -1";
    programs.zsh.shellAliases.la = "ls -a";
    programs.zsh.shellAliases.ll = "ls -l";

    programs.zsh.shellAliases.grep = "grep --color=auto";
    programs.zsh.shellAliases.vi = "vim";

    programs.zsh.enable = true;

    programs.zsh.enableCompletion = true;

    programs.zsh.initExtra = ''
      setopt \
        case_glob \
        extended_glob \
        glob_complete

      source ${pkgs.fetchFromGitHub {
        owner = "zdharma"; repo = "fast-syntax-highlighting";
        rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e"; sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
      }}/fast-syntax-highlighting.plugin.zsh

      source ${pkgs.fetchFromGitHub {
        owner = "hlissner"; repo = "zsh-autopair";
        rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1"; sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
      }}/autopair.zsh

      source ${./modules.d/zsh/zsh.d/vi.zsh}

      zstyle ':completion:*' menu select
      zstyle ':completion:*' rehash true
      source ${pkgs.fzf}/share/fzf/completion.zsh

      HISTSIZE=99999 SAVEHIST=$HISTSIZE
      HISTFILE=~/.cache/zsh_history
      setopt \
        extended_history \
        hist_ignore_all_dups \
        hist_ignore_space \
        hist_reduce_blanks \
        share_history

      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      source ${./modules.d/zsh/zsh.d/prompt.zsh}

      source ${./modules.d/zsh/zsh.d/global-aliases.zsh}
    '';

    home.file.".inputrc".text = ''
      set editing-mode vi

      set completion-ignore-case on
      set show-all-if-ambiguous on

      set keymap vi
      C-r: reverse-search-history
      C-f: forward-search-history
      C-l: clear-screen
      v: rlwrap-call-editor
    '';
  };

  environment.variables.PUSHOVER_USER = builtins.getEnv "PUSHOVER_USER";
  environment.variables.PUSHOVER_TOKEN = builtins.getEnv "PUSHOVER_TOKEN";

  services.upower.enable = true;
  services.batteryNotifier = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };
}
