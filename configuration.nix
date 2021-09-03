{ lib, pkgs, config, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./modules/home-manager.nix
    ./cachix.nix

    ./modules/adb.nix
    ./modules/adblock.nix
    ./modules/dict.nix
    ./modules/alacritty/alacritty.nix
    ./modules/aria2.nix
    # ./modules/chrome
    ./modules/flakes.nix
    ./modules/flatpak.nix
    ./modules/vim-as-manpager.nix
    ./modules/clipman.nix
    ./modules/clojure
    ./modules/clojure/boot
    ./modules/clojure/rebel-readline.nix
    ./modules/cloudflare-dns.nix
    ./modules/command-not-found.nix
    ./modules/cuff.nix # torrent search cli
    ./modules/curl.nix
    ./modules/direnv.nix
    ./modules/docker.nix
    # ./modules/dropbox.nix
    ./modules/emacs.nix
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
    ./modules/gebaard.nix
    ./modules/gtk.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/hardware-video-acceleration/mpv.nix
    ./modules/hidpi/console.nix
    ./modules/hidpi/gnome.nix # TODO: dconf needed?
    ./modules/hidpi/qt.nix
    # ./modules/himalaya.nix # email client
    ./modules/insync.nix
    # ./modules/ipfs.nix
    ./modules/kdeconnect.nix
    ./modules/keybase-files.nix
    # ./modules/keybase-sync.nix
    ./modules/keybase.nix
    ./modules/less.nix
    ./modules/libvirt.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    ./modules/mako.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mdns.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/mpv.nix
    # ./modules/networkmanager-iwd.nix
    ./modules/networkmanager.nix
    ./modules/ngrok.nix
    ./modules/nix-ld.nix
    ./modules/pipewire.nix
    ./modules/play-with-mpv.nix
    # ./modules/plymouth.nix # boot animations
    ./modules/printing.nix
    ./modules/readline/inputrc.nix
    ./modules/ripgrep.nix
    # ./modules/scanning.nix
    ./modules/spotify.nix
    ./modules/sway-autorotate-screen.nix
    ./modules/sway-autostart.nix
    ./modules/sway.nix
    ./modules/swayidle.nix
    ./modules/swaylock.nix
    ./modules/tailscale.nix
    ./modules/tmux.nix
    ./modules/tor.nix
    # ./modules/v5l2loopback.nix
    ./modules/virtualbox-host.nix
    ./modules/wayland.nix
    ./modules/wayland-qt.nix
    # ./modules/wl-clipboard-x11.nix
    # ./modules/wayvnc.nix
    # ./modules/weechat-matrix.nix
    ./modules/weechat.nix
    ./modules/wireguard.nix
    ./modules/wob.nix
    # ./modules/xdg-desktop-portal.nix
    ./modules/zsh/functions.nix
    ./modules/zsh/fzf.nix
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

  boot.loader.timeout = 0;

  security.sudo.wheelNeedsPassword = false;

  # automount removable devices
  services.devmon.enable = true;

  system.stateVersion = "19.09";

  nix.gc.automatic = true;

  nix.optimise.automatic = true;

  # nix.nixPath = [
  #   "nixpkgs=/home/avo/gdrive/nixpkgs"
  #   "nixos-config=/home/avo/gdrive/nixos-config/configuration.nix"
  # ];

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
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.avo = { pkgs, ... }:
    let
      vim = pkgs.callPackage ./modules/vim { };
    in rec {
      nixpkgs.overlays = config.nixpkgs.overlays;

      home.packages = (import ./packages.nix pkgs) ++ [
        vim
      ];

      home.sessionVariables = {
        EDITOR = "vim";
        PAGER = "nvimpager";
        BROWSER = "google-chrome-stable";
      };

      home.sessionPath = [
        "$HOME/gdrive/bin"
        (builtins.toString ./bin)
      ];

      xdg.enable = true;

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

        shellAliases = {
          git = "GPG_TTY=$(tty) git";
          rm = "rm --verbose";
          grep = "grep --color";
          l = "ls -1";
          la = "ls -a";
          ll = "ls -l";
          ls = "ls --human-readable --classify";
        };

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

          # set terminal title
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

  services.vnstat.enable = true;

  services.sysstat.enable = true;

  programs.steam.enable = true;
}
