{ lib, pkgs, ... }:

let
  theme = import ./modules/theme.nix;

  EDITOR = "${vim}/bin/vim";
  PAGER = "${pkgs.page}/bin/page";
  BROWSER = "${pkgs.google-chrome}/bin/google-chrome-stable";

  vim = pkgs.callPackage ./modules/vim.nix { };

  packages = with pkgs; [
    # (pkgs.youtube-viewer.overrideAttrs (oldAttrs: rec { src = /home/avo/gdrive/youtube-viewer; }))
    # chromiumDev
    # torbrowser
    abduco
    acpi
    aria
    aspell
    aspellDicts.en
    avo.colorpicker
    avo.pushover
    avo.scripts
    avo.zprint
    awscli
    babashka
    bat
    bc
    bluetooth_battery
    chromedriver
    clipman
    cloc
    clojure
    curl
    delta
    dnsutils
    dogdns
    dos2unix
    dtach
    dtrx
    entr
    ffmpeg-full # -full for ffplay
    file
    firefox
    fuse
    fx # JSON processing tool
    fzf
    fzy
    gcc
    geoip
    gh
    gist
    git
    git-hub
    gitAndTools.tig
    glpaper
    gnumake
    gnupg
    google-chrome
    google-cloud-sdk
    graphicsmagick
    haskellPackages.ShellCheck
    heroku
    httpie
    hub
    iftop
    imv
    iotop
    jq
    lastpass-cli
    libarchive # bsdtar
    libnotify
    libreoffice-fresh
    lsof
    mediainfo
    moreutilsWithoutParallel # moreutils parallel conflicts with GNU parallel
    mosh
    msmtp
    mupdf
    ncdu
    neomutt
    netcat
    nethogs
    ngrok
    nix-index
    nix-update
    nixops
    nmap
    nodePackages.peerflix
    nodePackages.webtorrent-cli
    openssl
    pamixer
    pandoc
    parallel
    patchelf
    pavucontrol
    playerctl
    protonvpn-cli
    psmisc
    pup
    puppeteer-cli
    pv
    pwgen
    python3
    qemu
    ranger
    recode
    ripgrep
    rlwrap
    rmlint
    skype
    socat
    sox
    speedtest_cli
    sqlite
    sshfsFuse
    sshuttle
    strace
    sublime3
    surf
    t
    tdesktop
    telnet
    tmate
    tree
    ungoogled-chromium # or chromium
    unrar
    unzip
    usbutils
    vifm
    vim
    vlc
    wf-recorder
    wget
    wgetpaste
    wine
    wireshark
    with-shell # cd inside commands
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

    (import "${builtins.fetchTarball "https://github.com/rycee/home-manager/archive/master.tar.gz"}/nixos")

    ./profiles/gui.nix
    ./profiles/workstation.nix

    # ./modules/weechat-matrix.nix
    ./modules/adb.nix
    ./modules/alacritty/alacritty.nix
    ./modules/aria2.nix
    ./modules/cloudflare-dns.nix
    ./modules/command-not-found.nix
    ./modules/curl.nix
    ./modules/weechat.nix
    ./modules/docker.nix
    ./modules/firefox-wayland.nix
    ./modules/fonts.nix
    ./modules/fzf.nix
    ./modules/git.nix
    ./modules/gnome-keyring.nix
    ./modules/grep.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/hardware-video-acceleration/mpv.nix
    ./modules/hidpi/console.nix
    ./modules/hidpi/gnome.nix
    ./modules/hosts-blocking.nix
    ./modules/insync.nix
    ./modules/ipfs.nix
    ./modules/kdeconnect.nix
    ./modules/less.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mpv.nix
    ./modules/npm-global-packages.nix
    ./modules/pipewire.nix
    ./modules/readline/inputrc.nix
    ./modules/ripgrep.nix
    ./modules/spotify.nix
    ./modules/sway/sway.nix
    ./modules/tor.nix
    ./modules/zsh/fzf.nix
    ./modules/zsh/vi.nix
  ];

  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-unstable";
  };

  system.stateVersion = "19.09";

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = with pkgs; [
    (import ./packages)
    (self: super: {
      moreutilsWithoutParallel = lib.overrideDerivation super.moreutils (attrs: {
        postInstall = attrs.postInstall + "\n"
          + "rm $out/bin/parallel $out/share/man/man1/parallel.1";
      });
    })
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.avo = { pkgs, ... }: {
    home.packages = packages;

    home.sessionVariables = {
      inherit EDITOR PAGER BROWSER;
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    xdg.configFile."mimeapps.list".text = lib.generators.toINI { } {
      "Default Applications" = {
        "application/pdf" = "mupdf.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "text/html" = "google-chrome.desktop";
        "text/plain" = "neovide.desktop";
        "video/mp4" = "mpv.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/tg" = "telegramdesktop.desktop";
      };
    };

    programs.zsh = {
      enable = true;

      enableCompletion = true;

      history = rec {
        size = 99999;
        save = size;
        share = true;
        ignoreSpace = true;
        ignoreDups = true;
        extended = true;
        path = ".cache/zsh_history";
      };

      shellGlobalAliases = {
        H = "| head";
        T = "| tail";
        C = "| wc -l";
        G = "| grep";
        L = "| ${PAGER}";
        NE = "2>/dev/null";
        NUL = "&>/dev/null";
      };

      shellAliases = {
        ls = "ls --human-readable --classify";
        l = "ls -1";
        la = "ls -a";
        ll = "ls -l";
        grep = "grep --color";
        vi = "vim";
      };

      plugins = with pkgs; [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.2.0";
            sha256 = "1gfyrgn23zpwv1vj37gf28hf5z0ka0w5qm6286a7qixwv7ijnrx9";
          };
        }
        {
          name = "fast-syntax-highlighting";
          file = "fast-syntax-highlighting.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "zdharma";
            repo = "fast-syntax-highlighting";
            rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e";
            sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
          };
        }
        {
          name = "autopair";
          file = "autopair.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1";
            sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
          };
        }
      ];

      initExtra = ''
        # trigger completion on globbing
        setopt glob_complete
        # remove extraneous spaces from saved commands
        setopt hist_reduce_blanks
        # show menu when completing
        zstyle ':completion:*' menu select
        # automatically update PATH
        zstyle ':completion:*' rehash true

        source ${./modules/zsh/prompt.zsh}
        source ${./modules/zsh/terminal-title.zsh}
      '';
    };
  };

  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  services.upower.enable = true;

  services.sshd.enable = true;
}
