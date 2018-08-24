{ config, lib, pkgs, ... }:

rec {
  imports = [
    ./hardware-configuration.nix

    "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"

    ./gui
    ./hardware
    ./networking.nix
    ./shell.nix

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
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/google-drive.nix
    ./programs/grep.nix
    ./programs/httpie.nix
    ./programs/ipfs.nix
    ./programs/irc.nix
    ./programs/less.nix
    ./programs/libvirt.nix
    ./programs/mpv.nix
    ./programs/neovim.nix
    ./programs/nginx-proxy.nix
    ./programs/parallel.nix
    ./programs/readline.nix
    ./programs/ripgrep.nix
    ./programs/ssh.nix
    ./programs/sshd.nix
    ./programs/tmux.nix
    ./programs/zathura.nix
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
   if builtins.getEnv "HOST" == "watts" then
     [ { interface = "enp0s31f6"; method = "magicpacket"; } ]
   else [];

  nixpkgs.config.allowUnfree = true;

  networking.extraHosts = builtins.readFile (builtins.fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts);

  nixpkgs.overlays =
    let path = ./overlays; in with builtins;
    map (n: import (path + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
                (attrNames (readDir path)));

  home-manager.users.avo = {
    nixpkgs.config = config.nixpkgs.config;

    home.sessionVariables = {
      BROWSER = "${pkgs.google-chrome-dev}/bin/google-chrome-unstable";
      EDITOR  = "${pkgs.neovim}/bin/nvim";
    };

    xdg.enable = true;

    xdg.configFile."user-dirs.dirs".text = lib.generators.toKeyValue {} {
      XDG_DOWNLOAD_DIR = "$HOME/tmp";
      XDG_DESKTOP_DIR  = "$HOME/tmp";
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
    moreutils-without-parallel =
      pkgs.stdenv.lib.overrideDerivation
        pkgs.moreutils
        (attrs: { postInstall = attrs.postInstall + "; rm $out/bin/parallel"; });
  in [
    acpi
    aria
    binutils
    disposable-browser
    dnsutils
    dtrx
    emacs-browse-url
    file
    flameshot
    gcolor2
    google-chrome-dev
    google-cloud-sdk
    google-play-music-desktop-player
    graphicsmagick
    gron
    icdiff
    inotify-tools
    jo
    jq
    jre
    keybase
    lastpass-cli
    libnotify
    libreoffice
    lsof
    moreutils-without-parallel
    mosh
    netcat
    nethogs
    ngrep
    ngrok
    nix-zsh-completions
    nixops
    nmap
    ntfy
    openssl
    pandoc
    psmisc
    pushover
    pv
    racket
    recode
    remarshal
    rsync
    socat
    strace
    surfraw
    sxiv
    telnet
    terminal-scratchpad
    texlive.combined.scheme-full
    tmate
    torbrowser
    traceroute
    tree
    tsocks
    units
    urlp
    webapp
    whattimeisit
    wireshark
    wsta
    xfce.thunar
    xurls
  ];
}
