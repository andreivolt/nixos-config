{ config, lib, pkgs, ... }:

rec {
  imports = [
    ./hardware-configuration.nix

    "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"

    ./gui
    ./hardware
    ./networking.nix

    # ./programs/mitmproxy.nix
    ./programs/alacritty.nix
    ./programs/android.nix
    ./programs/aws-cli.nix
    ./programs/bitcoin.nix
    ./programs/clojure
    ./programs/docker.nix
    ./programs/emacs.nix
    ./programs/email
    ./programs/fzf.nix
    ./programs/ghi.nix
    ./programs/gist.nix
    ./programs/git-hub.nix
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/google-drive.nix
    ./programs/grep.nix
    ./programs/httpie.nix
    ./programs/irc.nix
    ./programs/less.nix
    ./programs/libvirt.nix
    ./programs/macos-vm.nix
    ./programs/mosh.nix
    ./programs/mpv.nix
    ./programs/neovim.nix
    ./programs/nginx-proxy.nix
    ./programs/nodejs.nix
    ./programs/parallel.nix
    ./programs/pushover.nix
    ./programs/readline.nix
    ./programs/ripgrep.nix
    ./programs/ssh.nix
    ./programs/sshd.nix
    ./programs/tmux.nix
    ./programs/zathura.nix
    ./programs/zsh.nix
  ];

  boot.kernel.sysctl =
    { "fs.inotify.max_user_watches" = 100000; } //
    { "vm.swappiness" = 1; "vm.vfs_cache_pressure" = 50; };

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.avo = { isNormalUser = true; extraGroups = [ "wheel" ]; };
  security.sudo.wheelNeedsPassword = false;

  nix = {
    buildCores = 0;
    gc.automatic = true; optimise.automatic = true;
  };

  system.autoUpgrade = { enable = true; channel = "https://nixos.org/channels/nixos-unstable"; };

  system.stateVersion = "18.09";

  services.wakeonlan.interfaces =
    if builtins.getEnv "HOST" == "watts" then [ { interface = "enp0s31f6"; method = "magicpacket"; } ] else [];

  nixpkgs.config.allowUnfree = true;

  networking.extraHosts = builtins.readFile (builtins.fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts);

  environment.variables.BROWSER = "${pkgs.google-chrome-dev}/bin/google-chrome-unstable";

  home-manager.users.avo = {
    nixpkgs.config = config.nixpkgs.config;

    xdg.enable = true;

    xdg.configFile."user-dirs.dirs".text = lib.generators.toKeyValue {} {
      XDG_DOWNLOAD_DIR = "$HOME/tmp";
      XDG_DESKTOP_DIR = "$HOME/tmp";
    };

    xdg.configFile."mimeapps.list".text =
      let
        browser = "google-chrome-unstable";
        editor = "emacs";
      in lib.generators.toINI {} {
        "Default Applications" = {
          "application/pdf" = "org.pwmt.zathura.desktop";
          "application/xhtml+xml" = "${browser}.desktop";
          "application/xml" = "${editor}.desktop";
          "text/html" = "${browser}.desktop";
          "text/plain" = "${editor}.desktop";
          "x-scheme-handler/ftp" = "${browser}.desktop";
          "x-scheme-handler/http" = "${browser}.desktop";
          "x-scheme-handler/https" = "${browser}.desktop";
        };
      };
  };

  services.devmon.enable = true;

  environment.systemPackages = with pkgs; let
    google-search = stdenv.mkDerivation rec {
      name = "google-search";

      src = [(writeScript name ''
        ${pkgs.surfraw}/bin/surfraw google *
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    new-browser-tab = stdenv.mkDerivation rec {
      name = "new-browser-tab";

      src = [(writeScript name ''
        sleep 0.1
        ${xdotool}/bin/xdotool \
          search --class Chrome \
          windowactivate --sync key --clearmodifiers --window 0 ctrl+t
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    disposable-browser = with pkgs; stdenv.mkDerivation rec {
      name = "disposable-browser";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        setsid \
          ${pkgs.google-chrome-dev}/bin/google-chrome-unstable \
            --user-data-dir=$(mktemp -d) \
            --no-first-run --no-default-browser-check \
            $* &>/dev/null
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    webapp = with pkgs; stdenv.mkDerivation rec {
      name = "webapp";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        name=$1
        url=$2

        ${pkgs.google-chrome-dev}/bin/google-chrome-unstable \
            --class=webapp \
            --app="$url" \
            --no-first-run --no-default-browser-check \
            --user-data-dir=$XDG_CACHE_HOME/''${name}-webapp \
            &>/dev/null &

        disown
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    moreutils-without-parallel =
      stdenv.lib.overrideDerivation
        moreutils
        (attrs: { postInstall = attrs.postInstall + "; rm $out/bin/parallel"; });
  in [
    acpi
    aria
    binutils
    disposable-browser
    dnsutils
    dtrx
    file
    flameshot
    gcolor2
    google-chrome-dev
    google-cloud-sdk
    google-search
    graphicsmagick
    gron
    jo
    jq
    keybase
    lastpass-cli
    libreoffice
    lsof
    moreutils-without-parallel
    netcat
    nethogs
    new-browser-tab
    ngrep
    ngrok
    nix-zsh-completions
    nixops
    nmap
    ntfy
    pandoc
    psmisc
    racket
    remarshal
    rsync
    socat
    strace
    sxiv
    telnet
    texlive.combined.scheme-full
    tmate
    torbrowser
    tree
    webapp
    wireshark
    xfce.thunar
  ];
}
