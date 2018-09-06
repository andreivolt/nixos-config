{ config, lib, pkgs, ... }:

rec {
  imports = [
    ./hardware-configuration.nix

    "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"

    ./gui
    ./hardware
    ./networking.nix

    # ./programs/mitmproxy.nix
    ./programs/android.nix
    ./programs/aws-cli.nix
    ./programs/bitcoin.nix
    ./programs/browser.nix
    ./programs/clojure
    ./programs/docker.nix
    ./programs/emacs
    ./programs/email
    ./programs/fzf.nix
    ./programs/gist.nix
    ./programs/git-hub.nix
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/google-drive.nix
    ./programs/google-search.nix
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
    ./programs/phone.nix
    ./programs/pushover.nix
    ./programs/readline.nix
    ./programs/ripgrep.nix
    ./programs/ssh.nix
    ./programs/sshd.nix
    ./programs/terminal.nix
    ./programs/tmux.nix
    ./programs/todos
    ./programs/webapp.nix
    ./programs/whatismyip.nix
    ./programs/zathura.nix
    ./programs/zsh
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
    if builtins.getEnv "HOSTNAME" == "watts" then [ { interface = "enp0s31f6"; method = "magicpacket"; } ] else [];

  nixpkgs.config.allowUnfree = true;

  networking.extraHosts = builtins.readFile (builtins.fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts);

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
    rebuild = with pkgs; stdenv.mkDerivation rec {
      name = "rebuild";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        CREDENTIALS=$(< /home/avo/lib/credentials.json) \
        HOSTNAME=''${HOSTNAME:-watts} \
          sudo -E \
            nixos-rebuild switch --upgrade
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
    dnsutils
    dtrx
    file
    flameshot
    gcolor2
    google-cloud-sdk
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
    ngrep
    ngrok
    nixops
    nmap
    ntfy
    pandoc
    psmisc
    racket
    rebuild
    remarshal
    rsync
    socat
    strace
    sxiv
    telnet
    tmate
    torbrowser
    tree
    wireshark
    xfce.thunar
  ];
}
