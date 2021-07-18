{ lib, pkgs, ... }:

let
  theme = import ./modules.d/theme.nix;

  font = "Ubuntu";

  browser = "google-chrome-stable";

  packages = with pkgs; [
    (callPackage ./packages/colorpicker.nix {})
    (callPackage ./packages/pushover.nix {
      user = builtins.getEnv "PUSHOVER_USER";
      token = builtins.getEnv "PUSHOVER_TOKEN";
    })
    (callPackage ./packages/zprint.nix {})
    # moreutils parallel conflicts with GNU parallel
    (lib.overrideDerivation moreutils (attrs: {
      postInstall = attrs.postInstall + "\n" +
        "rm $out/bin/parallel $out/share/man/man1/parallel.1";
    }))
    # torbrowser
    acpi
    aria
    babashka
    bat
    bc
    bluetooth_battery
    chromedriver
    clipman
    clojure
    curl
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
    gphotos-sync
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
    (import "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos")

    # ./modules.d/curl.nix
    ./modules.d/adb.nix
    ./modules.d/adblock.nix
    ./modules.d/ipfs.nix
    ./modules.d/alacritty/alacritty.nix
    ./modules.d/cloudflare-dns.nix
    ./modules.d/docker.nix
    ./modules.d/firefox.nix
    ./modules.d/fonts.nix
    ./modules.d/fzf.nix
    ./modules.d/git.nix
    ./modules.d/hardware-video-acceleration.nix
    ./modules.d/insync.nix
    ./modules.d/kdeconnect.nix
    ./modules.d/low-bat-suspend.nix
    ./modules.d/map-test-tld-to-localhost.nix
    ./modules.d/npm.nix
    ./modules.d/pipewire.nix
    ./modules.d/readline/inputrc.nix
    ./modules.d/ripgrep.nix
    ./modules.d/sway.nix
    ./modules.d/tor.nix
    ./modules.d/command-not-found.nix
    ./modules.d/vim.nix
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

  nix.gc.automatic = true;
  nix.optimise.automatic = true;

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = builtins.getEnv "HOSTNAME";

  networking.enableIPv6 = false;

  networking.networkmanager.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  home-manager.users.avo = { pkgs, config, ... }: {
    gtk.enable = true;
    gtk.theme.name = "dark";
    # gtk.theme.package = pkgs.gnome-breeze;
    gtk.font.name = "${font} 8";

    home.sessionPath = [ "$HOME/.local/bin" ];

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        scaling-factor = 2;
      };
    };

    # notifications
    programs.mako = {
      enable = true;
      width = 500;
      backgroundColor = "#00000050";
      font = "${font} 30";
      layer = "overlay";
      borderSize = 0;
      margin = "20";
      padding = "20";
    };

    home.sessionVariables = {
      BROWSER = browser;
      EDITOR = "vim";
      PAGER = "less";
      LC_COLLATE = "C";
      GREP_COLOR = "1"; # color matches yellow
      LESS = ''
        --RAW-CONTROL-CHARS \
        --ignore-case \
        --no-init \
        --quit-if-one-screen\
      '';
      LS_COLORS = ''
        di=0;35:\
        fi=0;37:\
        ex=0;96:\
        ln=0;37\
      '';
    };

    home.packages = packages;

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    xdg.configFile."mimeapps.list".text = lib.generators.toINI {} {
      "Default Applications" = {
        "application/pdf" = "mupdf.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "text/html" = "google-chrome.desktop";
        "text/plain" = "nvim.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
      };
    };

    programs.zsh = {
      enable = true;

      enableCompletion = true;

      shellGlobalAliases = {
        H = "| head";
        T = "| tail";
        C = "| wc -l";
        G = "| grep";
        L = "| less";
        M = "| most";
        LL = "2>&1 | less";
        CA = "2>&1 | cat -A";
        NE = "2> /dev/null";
        NUL = "> /dev/null 2>&1";
      };

      shellAliases = {
        ls = "ls --human-readable --indicator-style=slash";
        l = "ls -1";
        la = "ls -a";
        ll = "ls -l";
        grep = "grep --color=auto";
        vi = "vim";
      };

      plugins = [
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

      history = rec {
        save = size;
        size = 99999;
        share = true;
        ignoreSpace = true;
        ignoreDups = true;
        extended = true;
        path = ".cache/zsh_history";
      };

      initExtra = ''
        setopt \
          case_glob \
          extended_glob \
          glob_complete

        setopt hist_reduce_blanks

        zstyle ':completion:*' menu select

        # automatically update PATH
        zstyle ':completion:*' rehash true

        source ${./modules.d/zsh/zsh.d/prompt.zsh}
        source ${./modules.d/zsh/zsh.d/terminal-title.zsh}
        source ${./modules.d/zsh/zsh.d/vi.zsh}

        source ${pkgs.fzf}/share/fzf/completion.zsh
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      '';
    };
  };

  services.upower.enable = true;
  services.batteryNotifier = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  programs.dconf.enable = true;
}
