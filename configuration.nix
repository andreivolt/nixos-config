{ config, lib, pkgs, ... }:

rec {
  imports = [
    ./hardware-configuration.nix

    ./home-manager/nixos

    ./hardware

    ./gui
    ./netrc.nix
    ./networking
    ./shell.nix

    # ./programs/mitmproxy.nix
    ./programs/alacritty.nix
    ./programs/android.nix
    ./programs/aws-cli.nix
    ./programs/bitcoin.nix
    ./programs/clojure
    ./programs/docker
    ./programs/emacs.nix
    ./programs/email
    ./programs/fzf.nix
    ./programs/ghi.nix
    ./programs/gist.nix
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/google-drive.nix
    ./programs/grep.nix
    ./programs/haskell
    ./programs/httpie.nix
    ./programs/hub.nix
    ./programs/ipfs.nix
    ./programs/irc.nix
    ./programs/less.nix
    ./programs/libvirt.nix
    ./programs/mpv.nix
    ./programs/neovim.nix
    ./programs/nodejs.nix
    ./programs/parallel.nix
    ./programs/qutebrowser.nix
    ./programs/readline.nix
    ./programs/ripgrep.nix
    ./programs/ssh.nix
    ./programs/sxiv.nix
    ./programs/tmux.nix
    ./programs/zathura.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  system.nixos.stateVersion = "18.09";

  services.wakeonlan.interfaces =
   if builtins.getEnv "HOST" == "watts" then
     [ { interface = "enp0s31f6"; method = "magicpacket"; } ]
   else [];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays =
    let path = ./overlays; in with builtins;
    map (n: import (path + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
                (attrNames (readDir path)));

  home-manager.users.avo = {
    nixpkgs.config = config.nixpkgs.config;

    home.sessionVariables = with config.home-manager.users.avo; {
      BROWSER = "${pkgs.qutebrowser}/bin/qutebrowser";
      EDITOR  = "${pkgs.neovim}/bin/nvim";
      PATH    = lib.concatStringsSep ":" [ "$PATH" "$HOME/.local/bin" ];
    };

    xdg.enable = true;

    xdg.configFile."user-dirs.dirs".text = lib.generators.toKeyValue {} {
      XDG_DOWNLOAD_DIR = "$HOME/tmp";
      XDG_DESKTOP_DIR  = "$HOME/tmp";
    };

    xdg.configFile."mimeapps.list".text =
      let browser = "qutebrowser"; editor = "emacs"; in lib.generators.toINI {} {
        "Default Applications" = {
          "application/pdf"                                                         = "zathura.desktop";
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = "calc.desktop";
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
          "application/xhtml+xml"                                                   = "${browser}.desktop";
          "application/xml"                                                         = "${editor}.desktop";
          "text/html"                                                               = "${browser}.desktop";
          "text/plain"                                                              = "${editor}.desktop";
          "x-scheme-handler/ftp"                                                    = "${browser}.desktop";
          "x-scheme-handler/http"                                                   = "${browser}.desktop";
          "x-scheme-handler/https"                                                  = "${browser}.desktop";
        };
      };
  };

  services.devmon.enable = true;

  fileSystems."scripts" = {
    device = "/etc/nixos/scripts";
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.local/bin";
  };

  environment.systemPackages = with pkgs; [
    # gron
    acpi
    aria
    avo-scripts
    binutils
    dnsutils
    dtrx
    file
    flameshot
    gcolor2
    gnumake
    google-chrome-dev
    google-cloud-sdk
    google-play-music-desktop-player
    graphicsmagick
    icdiff
    inkscape
    inotify-tools
    jo
    jq
    jre
    keybase
    lastpass-cli
    libnotify
    libreoffice
    linuxPackages.perf
    lsof
    moreutilsWithoutParallel
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
    perlPackages.HTMLParser
    psmisc
    pup
    pv
    qutebrowser-scripts
    racket
    recode
    remarshal
    reptyr
    rlwrap
    rsync
    socat
    strace
    surfraw
    telnet
    texlive.combined.scheme-full
    tmate
    tmux
    torbrowser
    traceroute
    tree
    tsocks
    units
    urlp
    wireshark
    wsta
    xfce.thunar
    xurls
  ];
}
