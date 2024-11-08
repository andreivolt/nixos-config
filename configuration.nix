{ pkgs, config, ... }:

{
  imports = [
    ./cachix.nix
    ./hardware-configuration.nix
    ./modules/adb.nix
    ./modules/adblock.nix
    ./modules/alacritty/alacritty.nix
    ./modules/aria2.nix
    ./modules/clipman.nix
    ./modules/clojure.nix
    ./modules/command-not-found.nix
    ./modules/cuff.nix
    ./modules/cursor.nix
    ./modules/dict.nix
    ./modules/disable-ipv6.nix
    ./modules/docker.nix
    ./modules/fbterm.nix
    ./modules/fingerprint-unlock.nix
    ./modules/firefox-wayland.nix
    ./modules/flashfocus.nix
    ./modules/flatpak.nix
    ./modules/fonts.nix
    ./modules/gnome-keyring.nix
    ./modules/gnupg.nix
    ./modules/grep.nix
    ./modules/gtk.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/hardware-video-acceleration/mpv.nix
    ./modules/hidpi/console.nix
    ./modules/hidpi/gnome.nix
    ./modules/hidpi/qt.nix
    ./modules/keybase-files.nix
    ./modules/keybase.nix
    ./modules/less.nix
    ./modules/libvirt.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    ./modules/mako.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mdns.nix
    ./modules/mopidy.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/mpv.nix
    ./modules/networkmanager.nix
    ./modules/nextdns.nix
    ./modules/ngrok.nix
    ./modules/nix-ld.nix
    ./modules/nix.nix
    ./modules/nixos-rebuild-summary.nix
    ./modules/npm.nix
    ./modules/pipewire.nix
    ./modules/play-with-mpv.nix
    ./modules/printing.nix
    ./modules/qt.nix
    ./modules/scanning.nix
    ./modules/spotifyd.nix
    ./modules/sway-autorotate-screen.nix
    ./modules/sway-autostart.nix
    ./modules/sway.nix
    ./modules/swayidle.nix
    ./modules/swaylock.nix
    ./modules/tailscale.nix
    ./modules/tor.nix
    ./modules/v4l2loopback.nix
    ./modules/virtualbox-host.nix
    ./modules/wayland-qt.nix
    ./modules/wayland.nix
    ./modules/wayvnc.nix
    ./modules/weechat.nix
    ./modules/wob.nix
    ./modules/xdg-portals.nix
    ./modules/zsh/fzf.nix
  ]
  ++ [ <home-manager/nixos> ];

  # boot.kernelPackage = pkgs.linuxKernel.kernels.linux_lqx;
  # boot.kernelPackage = pkgs.linuxKernel.kernels.linuxKernel.kernels.linux_zen;

  networking.hostName = builtins.getEnv "HOSTNAME";

  services.sshd.enable = true;

  hardware.bluetooth.enable = true;

  hardware.opengl.enable = true;

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  # 24-hour time format
  environment.variables.LC_TIME = "C.UTF-8";

  # don't show boot options
  boot.loader.timeout = 0;

  security.sudo.wheelNeedsPassword = false;

  # automount removable devices
  services.devmon.enable = true;
  # services.udisks2.enable = true;

  system.stateVersion = "19.09";

  # nix.nixPath = [ "nixos-config=/home/avo/gdrive/nixos-config/configuration.nix" ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays =
    let
      nixpkgsUnstable = self: super: {
        nixpkgsUnstable =
          let nixpkgs-unstable-src = fetchTarball "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
          in import nixpkgs-unstable-src { };
      };
      firefoxNightly =
        let src = fetchTarball { url = "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz"; };
        in import "${src}/firefox-overlay.nix";
    in
    [
      nixpkgsUnstable
      firefoxNightly
      (import ./packages)
      (self: super: {
        fcitx-engines = pkgs.fcitx5;
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

  environment.localBinInPath = true;
  environment.homeBinInPath = true;

  home-manager.users.avo = { pkgs, ... }: {
    nixpkgs.overlays = config.nixpkgs.overlays;

    services.playerctld.enable = true;

    home.stateVersion = "22.05";

    dconf.settings."org/gnome/desktop/interface" = {
      font-name = "Ubuntu 12";
    };

    home.packages = import ./packages.nix pkgs;

    home.sessionVariables = {
      EDITOR = "vim";
      BROWSER = "firefox";
    };

    home.sessionPath = [
      "$HOME/drive/bin"
      "$HOME/.local/bin"
      "$HOME/go/bin"
      (builtins.toString ./bin)
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
    xdg.mimeApps.defaultApplications =
      let
        browser = "firefox";
      in
      {
        "application/pdf" = "org.pwmt.zathura.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "inode/directory" = "thunar.desktop";
        "text/html" = "${browser}.desktop";
        "text/plain" = "sublime_text.desktop";
        "video/mp4" = "mpv.desktop";
        "x-scheme-handler/http" = "${browser}.desktop";
        "x-scheme-handler/https" = "${browser}.desktop";
        # "text/plain" = "neovide.desktop";
        # x-scheme-handler/tg=userapp-Telegram Desktop-O8HQU1.desktop;
        # x-scheme-handler/ytmd=youtube-music-desktop-app.desktop
      };
    xdg.configFile."mimeapps.list".force = true;

    programs.lesspipe.enable = true;

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;

    # programs.zsh.enableCompletion = false;

    # programs.zsh.enableInteractiveComments = true; # TODO not on home-manager

    programs.zsh.enableSyntaxHighlighting = true;

    programs.zsh.historySubstringSearch.enable = true;

    programs.zsh.defaultKeymap = "viins";

    # TODO
    programs.zsh.enable = true; # TODO
    # programs.zsh.enableSyntaxHighlighting = true;

    programs.zsh.initExtra = "source ~/.zshrc.extra.zsh;";
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

  programs.zsh.enable = true;

  programs.mosh.enable = true;

  services.gvfs.enable = true;
}
