{ config, lib, pkgs, ... }:

let
  makeEmacsDaemon = import ./make-emacs-daemon.nix;

  theme = import ./challenger-deep-theme.nix;
  proportionalFont = "Abel"; monospaceFont = "Source Code Pro";

  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";


in {
  imports =
    [
      ./hardware-configuration.nix

      ./home-manager/nixos

      ./android.nix
      ./clojure.nix
      ./docker.nix
      ./email.nix
      ./git.nix
      ./google-drive-ocamlfuse-service.nix
      ./gui.nix
      ./haskell.nix
      ./input.nix
      ./ipfs.nix
      ./irc.nix
      ./libvirt.nix
      ./networking.nix
      ./packages.nix
      ./printing.nix
      ./shell.nix
    ];

  boot.loader.timeout = 1;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 100000;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
    "kernel.core_pattern" = "|/run/current-system/sw/bin/false"; # disable core dumps
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.pathsToLink = [ "/share/zsh" ];

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  nix = {
    buildCores = 0;
    gc.automatic = true;
    optimise.automatic = true;
  };

  nixpkgs = {
    overlays = import ./overlays.nix;
    config.allowUnfree = true;
  };

  hardware = {
    bluetooth.enable = true;

    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
  };

  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  services = {
    devmon.enable = true;

    mopidy = {
      enable = true;
      extensionPackages = with pkgs; [ mopidy-gmusic ];
      configuration = lib.generators.toINI {} {
        gmusic = {
          deviceid = "0123456789abcdef";
          username = "andreivolt";
          password = builtins.getEnv "ANDREIVOLT_GOOGLE_PASSWORD";
          bitrate = 320;
        };
      };
    };

    emacs.enable = true;

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];

      displayManager.auto = { enable = true; user = "avo"; };
      desktopManager.xterm.enable = false;
      # displayManager.sddm.enable = true;
      # windowManager.sway.enable = true;
    };
  };

  users.users.avo = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  home-manager.users.avo = let home_directory = builtins.getEnv "HOME"; in rec {
    services.dropbox.enable = true;

    home = {
      sessionVariables = {
        ALTERNATE_EDITOR            = "${pkgs.neovim}/bin/nvim";
        BROWSER                     = "${pkgs.qutebrowser}/bin/qutebrowser-open-in-instance";
        EDITOR                      = ''
                                         ${pkgs.emacs}/bin/emacsclient \
                                         --tty \
                                         --create-frame'';
        PATH                        = lib.concatStringsSep ":" [
                                        "$PATH"
                                        "$HOME/bin"
                                        "${xdg.cacheHome}/npm/packages/bin"
                                      ];
        GNUPGHOME                   = "${xdg.configHome}/gnupg";
        LESSHISTFILE                = "${xdg.cacheHome}/less/history";
        LIBVA_DRIVER_NAME           = "vdpau";
        PARALLEL_HOME               = "${xdg.cacheHome}/parallel";
        WWW_HOME                    = "${xdg.cacheHome}/w3m";
        __GL_SHADER_DISK_CACHE_PATH = "${xdg.cacheHome}/nv";
      };

      file = {
        ".trc".text =
          let
            username       = "andreivolt";
            consumerKey    = builtins.getEnv "TWITTER_CONSUMER_KEY";
            consumerSecret = builtins.getEnv "TWITTER_CONSUMER_SECRET";
            token          = builtins.getEnv "TWITTER_TOKEN";
            secret         = builtins.getEnv "TWITTER_SECRET";
          in ''
            ---
            configuration:
              default_profile:
              - ${username}
              - ${consumerKey}
            profiles:
              ${username}:
                ${consumerKey}:
                  username: ${username}
                  consumer_key: ${consumerKey}
                  consumer_secret: ${consumerSecret}
                  token: ${token}
                  secret: ${secret}
          '';

        ".tmux.conf".text = import ./tmux.nix { inherit theme; };

        ".gist".text = builtins.getEnv "GIST_TOKEN";
      };
    };

    xdg = {
      enable = true;

      configHome = "${home_directory}/.config";
      dataHome   = "${home_directory}/.local/share";
      cacheHome  = "${home_directory}/.cache";

      configFile = {
        "bitcoin/bitcoin.conf".text = lib.generators.toKeyValue {} {
          prune = 550;
        };

        "mitmproxy/config.yaml".text = ''
           CA_DIR: ${xdg.configHome}/mitmproxy/certs
        '';

        "youtube-dl.conf".text = ''
           --output %(title)s.%(ext)s
        '';

        "qutebrowser/autoconfig.yml".text = lib.generators.toYAML {}
          (import ./qutebrowser.nix { inherit theme proportionalFont monospaceFont pkgs; });

        "user-dirs.dirs".text = lib.generators.toKeyValue {} {
          XDG_DOWNLOAD_DIR = "$HOME/tmp";
          XDG_DESKTOP_DIR  = "$HOME/tmp";
        };

        "mimeapps.list".text = lib.generators.toINI {} {
           "Default Applications" = {
             "x-scheme-handler/http"                                                   = "qutebrowser.desktop";
             "x-scheme-handler/https"                                                  = "qutebrowser.desktop";
             "x-scheme-handler/ftp"                                                    = "qutebrowser.desktop";
             "text/html"                                                               = "qutebrowser.desktop";
             "application/xhtml+xml"                                                   = "qutebrowser.desktop";
             "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
             "application/pdf"                                                         = "zathura.desktop";
             "text/plain"                                                              = "emacs.desktop";
             "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = "calc.desktop";
             "application/xml"                                                         = "emacs.desktop";
             "x-scheme-handler/magnet"                                                 = "userapp-transmission-gtk-NWT3FZ.desktop";
           };
         };
      };
    };

    nixpkgs.config = {
      allowUnfree = true;
    };

    programs = (import ./programs.nix { inherit config lib; });
  };

  systemd.user.services = {
    editorEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "scratchpad"; };
  };
}
