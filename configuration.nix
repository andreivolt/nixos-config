{ lib, pkgs, config, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./modules/home-manager.nix
    ./cachix.nix

    ./modules/adb.nix # linux
    # ./modules/adblock.nix
    ./modules/dict.nix # linux
    ./modules/alacritty/alacritty.nix
    ./modules/aria2.nix
    ./modules/bat.nix
    ./modules/npm.nix
    # ./modules/chrome
    ./modules/nix.nix
    ./modules/fbterm.nix # linux
    ./modules/flatpak.nix # linux
    ./modules/vim-as-manpager.nix
    ./modules/clipman.nix # linux
    ./modules/disable-ipv6.nix # linux
    ./modules/clojure
    ./modules/clojure/boot
    ./modules/clojure/rebel-readline.nix
    ./modules/cloudflare-dns.nix # nixos
    ./modules/command-not-found.nix
    ./modules/cuff.nix # torrent search cli # nixos
    ./modules/curl.nix
    ./modules/direnv.nix
    ./modules/docker.nix
    # ./modules/dropbox.nix
    # ./modules/emacs.nix
    ./modules/firefox-wayland.nix
    ./modules/flashfocus.nix
    ./modules/fonts.nix
    ./modules/foot.nix
    ./modules/fzf.nix
    ./modules/git.nix
    ./modules/github.nix
    ./modules/gnome-keyring.nix
    ./modules/gnupg.nix
    ./modules/grep.nix
    # ./modules/gebaard.nix
    ./modules/gtk.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/hardware-video-acceleration/mpv.nix
    ./modules/hidpi/console.nix
    ./modules/hidpi/gnome.nix # TODO: dconf needed?
    ./modules/hidpi/qt.nix
    ./modules/qt.nix
    ./modules/himalaya.nix # email client
    ./modules/insync.nix
    # ./modules/ipfs.nix
    # ./modules/kdeconnect.nix
    # ./modules/keybase-files.nix
    # ./modules/keybase-sync.nix
    ./modules/keybase.nix
    ./modules/less.nix
    ./modules/libvirt.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    # ./modules/mako.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mdns.nix
    ./modules/mopidy.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/mpv.nix
    # ./modules/networkmanager-iwd.nix
    ./modules/networkmanager.nix
    ./modules/ngrok.nix
    ./modules/nix-ld.nix
    ./modules/pipewire.nix
    # ./modules/play-with-mpv.nix
    # ./modules/plymouth.nix # boot animations
    ./modules/printing.nix
    ./modules/readline/inputrc.nix
    ./modules/ripgrep.nix
    ./modules/scanning.nix
    ./modules/spotify.nix
    ./modules/sway-autorotate-screen.nix
    ./modules/sway-autostart.nix
    ./modules/sway.nix
    ./modules/swayidle.nix
    ./modules/swaylock.nix
    ./modules/tailscale.nix
    ./modules/tmux.nix
    ./modules/tor.nix
    ./modules/v4l2loopback.nix
    ./modules/virtualbox-host.nix
    ./modules/wayland.nix
    ./modules/wayland-qt.nix
    # ./modules/wl-clipboard-x11.nix
    ./modules/wayvnc.nix
    # ./modules/weechat-matrix.nix
    ./modules/weechat.nix
    # ./modules/wireguard.nix
    ./modules/wob.nix
    ./modules/xdg-desktop-portal.nix
    ./modules/zsh/functions.nix
    ./modules/zsh/fzf.nix
    ./modules/zsh/starship.nix
    ./modules/zsh/prompt.nix
    ./modules/zsh/vi.nix
  ];

  networking.hostName = builtins.getEnv "HOSTNAME";

  services.sshd.enable = true;

  hardware.bluetooth.enable = true;

  hardware.opengl.enable = true;

  # services.udisks2.enable = true;

  documentation.man.generateCaches = true;

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  # 24-hour time format
  environment.variables.LC_TIME = "C.UTF-8";

  # don't show boot options
  boot.loader.timeout = 0;

  security.sudo.wheelNeedsPassword = false;

  # automount removable devices
  services.devmon.enable = true;

  system.stateVersion = "19.09";

  nix.gc.automatic = true;

  nix.optimise.automatic = true;

  # nix.nixPath = [ "nixos-config=/home/avo/gdrive/nixos-config/configuration.nix" ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = let
    nixpkgsUnstable = self: super: {
      nixpkgsUnstable =
        let nixpkgs-unstable-src = fetchTarball "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
        in import nixpkgs-unstable-src { };
    };
  in [
    nixpkgsUnstable
    (import ./packages)
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.avo = { pkgs, ... }: rec {
    nixpkgs.overlays = config.nixpkgs.overlays;

    dconf.settings."org/gnome/desktop/interface" = {
      font-name = "Ubuntu 12";
    };

    home.packages = import ./packages.nix pkgs;

    home.sessionVariables = {
      EDITOR = "vim";
      PAGER = "nvimpager";
      BROWSER = "google-chrome-stable";
    };

    home.sessionPath = [
      "$HOME/gdrive/bin"
      "$HOME/.local/bin"
      "$HOME/go/bin"
      (builtins.toString ./bin)
      "$HOME/.local/share/gem/ruby/2.7.0/bin"
    ];

    xdg.enable = true;

    xdg.userDirs = {
      enable = true;
      createDirectories = false;
      desktop = "$HOME/gdrive";
      documents = "$HOME/gdrive";
      download = "$HOME/gdrive";
    };

    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "application/pdf" = "zathura.desktop";
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "text/html" = "google-chrome-stable.desktop";
      "text/plain" = "neovide.desktop";
      "video/mp4" = "mpv.desktop";
      "x-scheme-handler/http" = "google-chrome-stable.desktop";
      "x-scheme-handler/https" = "google-chrome-stable.desktop";
    };

    programs.lesspipe.enable = true;

    programs.zsh = {
      enable = true;

      enableCompletion = true;

      enableSyntaxHighlighting = true;

      defaultKeymap = "viins";

      # enableInteractiveComments = true;

      history = rec {
        size = 999999;
        save = size;
        share = true;
        ignoreSpace = true;
        ignoreDups = true;
        extended = true;
        path = ".cache/zsh_history";
      };

      shellGlobalAliases = {
        C = "| wc -l";
        G = "| grep";
        H = "| head";
        L = "| nvimpager";
        NE = "2>/dev/null";
        NUL = "&>/dev/null";
        T = "| tail";
        X = "| xargs";
      };

      shellAliases = import ./aliases.nix;

      plugins = with pkgs; [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.2.0";
            sha256 = "1gfyrgn23zpwv1vj37gf28hf5z0ka0w5qm6286a7qixwv7ijnrx9";
          };
        }
        {
          name = "autopair";
          file = "autopair.zsh";
          src = fetchFromGitHub {
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

        # automatically add directories to the directory stack
        setopt auto_pushd

        # # set terminal title
        # source ${./modules/zsh/terminal-title.zsh}

        # case-insensitive completion
        zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        # autoload -Uz compinit && compinit
      '';
    };
  };

  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  services.upower.enable = true;

  services.vnstat.enable = true;

  services.sysstat.enable = true;

  programs.steam.enable = true;

  programs.mosh.enable = true;
}
