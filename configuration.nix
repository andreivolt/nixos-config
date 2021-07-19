{ lib, pkgs, ... }:

let
  theme = import ./modules/theme.nix;

  font = "Ubuntu";

  user = "avo";

  packages = with pkgs; [
    (callPackage ./packages/colorpicker.nix { })
    (callPackage ./packages/pushover.nix {
      user = builtins.getEnv "PUSHOVER_USER";
      token = builtins.getEnv "PUSHOVER_TOKEN";
    })
    (callPackage ./packages/zprint.nix { })
    # moreutils parallel conflicts with GNU parallel
    (lib.overrideDerivation moreutils (attrs: {
      postInstall = attrs.postInstall + "\n"
        + "rm $out/bin/parallel $out/share/man/man1/parallel.1";
    }))
    # torbrowser
    acpi
    aria
    awscli
    pv
    babashka
    bat
    bc
    bluetooth_battery
    chromedriver
    clipman
    clojure
    curl

    aspell
    aspellDicts.en
    dos2unix
    fuse
    gitAndTools.tig
    gnumake
    haskellPackages.ShellCheck
    ncdu
    neomutt
    ngrok
    pwgen
    ranger
    rmlint
    skype
    speedtest_cli
    sqlite
    sshfsFuse
    sshuttle
    unrar
    vifm
    wgetpaste
    wine
    wireshark
    entr
    abduco

    delta
    dnsutils
    dogdns
    dtach
    dtrx
    ffmpeg-full # -full for ffplay
    file
    firefox
    fzf
    fzy
    geoip
    gh
    gist
    git
    git-hub
    glpaper
    gnumake
    gnupg
    google-chrome
    google-cloud-sdk
    graphicsmagick
    httpie
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
    mosh
    mpv
    msmtp
    mupdf
    netcat
    nethogs
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
    ungoogled-chromium # or chromium
    unzip
    usbutils
    vlc
    wf-recorder
    wget
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

    ./modules/adb.nix
    ./modules/alacritty/alacritty.nix
    ./modules/battery-suspend.nix
    ./modules/cloudflare-dns.nix
    ./modules/command-not-found.nix
    ./modules/curl.nix
    ./modules/docker.nix
    ./modules/fonts.nix
    ./modules/fzf.nix
    ./modules/git.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/hidpi.nix
    ./modules/hosts-blocking.nix
    ./modules/insync.nix
    ./modules/ipfs.nix
    ./modules/kdeconnect.nix
    ./modules/less.nix
    ./modules/locate.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/mpv.nix
    ./modules/npm-global-packages.nix
    ./modules/pipewire.nix
    ./modules/readline/inputrc.nix
    ./modules/ripgrep.nix
    ./modules/sway/sway.nix
    ./modules/tor.nix
    ./modules/vim.nix
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

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  hardware.bluetooth.enable = true;

  hardware.opengl.enable = true;

  services.devmon.enable = true; # automount removable devices

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = builtins.getEnv "HOSTNAME";

  networking.enableIPv6 = false;

  networking.networkmanager.enable = true;

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  home-manager.users.avo = { pkgs, ... }: {
    home.packages = packages;

    home.sessionPath = [
      "$HOME/.local/bin"
      (builtins.toString ./bin)
    ];

    home.sessionVariables = {
      EDITOR = "vim";
      PAGER = "${pkgs.page}/bin/page";
      BROWSER = "google-chrome-stable";
      LC_COLLATE = "C";
      GREP_COLOR = "1"; # color matches yellow
      LS_COLORS = ''
        di=0;35:\
        fi=0;37:\
        ex=0;96:\
        ln=0;37\
      '';
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    gtk = {
      enable = true;
      theme.name = "dark";
      # gtk.theme.package = pkgs.gnome-breeze;
      font.name = "${font} 8";
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
      };
    };

    programs.zsh = {
      enable = true;

      enableCompletion = true;

      history = rec {
        save = size;
        size = 99999;
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
        L = "| less";
        LL = "2>&1 | less";
        CA = "2>&1 | cat -A";
        NE = "2> /dev/null";
        NUL = "> /dev/null 2>&1";
      };

      shellAliases = {
        ls = ''ls \
          --human-readable \
          --indicator-style=slash
        '';
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
        setopt \
          case_glob \
          extended_glob \
          glob_complete

        setopt hist_reduce_blanks

        zstyle ':completion:*' menu select

        # automatically update PATH
        zstyle ':completion:*' rehash true

        source ${./modules/zsh/prompt.zsh}

        source ${./modules/zsh/terminal-title.zsh}
      '';
    };
  };

  services.upower.enable = true;

  services.battery-suspend = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  services.sshd.enable = true;
}
