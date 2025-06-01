{
  pkgs,
  config,
  inputs,
  ...
}: {
  users.users.andrei = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
  };

  networking.hostName = builtins.getEnv "HOSTNAME";

  imports = [
    ./hardware-configuration.nix
    ./modules/linux/adb.nix
    ./modules/linux/brother-printer.nix
    ./modules/linux/brother-scanner.nix
    ./modules/clojure.nix
    ./modules/cursor.nix
    ./modules/linux/docker.nix
    ./modules/linux/fingerprint.nix
    ./modules/linux/flashfocus.nix
    ./modules/fonts.nix
    ./modules/linux/gnome-keyring.nix
    ./modules/gnupg.nix
    ./modules/linux/gtk.nix
    ./modules/linux/ipv6-disable.nix
    ./modules/insync.nix
    ./modules/linux/libvirt.nix
    ./modules/dnsmasq.nix
    ./modules/linux/lowbatt.nix
    ./modules/linux/mako.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/mpv.nix
    ./modules/linux/networkmanager.nix
    ./modules/nix.nix
    ./modules/linux/nixos-rebuild-summary.nix
    ./modules/linux/pipewire.nix
    ./modules/play-with-mpv.nix
    ./modules/linux/qt.nix
    ./modules/linux/sway.nix
    ./modules/linux/swayidle.nix
    ./modules/linux/swaylock.nix
    ./modules/linux/thinkpad-video.nix
    ./modules/tor.nix
    ./modules/linux/v4l2loopback.nix
    ./modules/linux/wayvnc.nix
    ./modules/linux/xdg-portals.nix
    ./modules/zsh-nix-completion.nix
    <home-manager/nixos>
  ];

  nixpkgs.config.allowUnfree = true;

  # don't show boot options
  boot.loader.timeout = 0;

  # # use maximum resolution in systemd-boot
  # boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";

  console.keyMap = "fr";

  console.earlySetup = true;
  console.font = "ter-132n";
  console.packages = [pkgs.terminus_font];

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  # 24-hour time format
  environment.variables.LC_TIME = "C.UTF-8";

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;

  i18n.consoleKeyMap = "fr";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.mosh.enable = true;

  programs.nix-ld.enable = true;

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  # automount removable devices
  services.devmon.enable = true;

  services.flatpak.enable = true;

  services.gvfs.enable = true;

  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  services.sshd.enable = true;

  services.tailscale.enable = true;

  services.upower.enable = true;

  time.timeZone = "Europe/Paris";

  home-manager.users.andrei = {pkgs, ...}: {
    nixpkgs.overlays = config.nixpkgs.overlays;

    home.packages = import "${inputs.self}/packages.nix" pkgs;

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true; # TODO
      enableCompletion = false;
      initExtra = "source ~/.zshrc.extra.zsh;";
    };

    services.clipman.enable = true;

    services.playerctld.enable = true;

    services.wob.enable = true;

    xdg.enable = true;

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      documents = "~/documents";
      download = "~/downloads";
    };

    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = let
      browser = "firefox";
    in {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "inode/directory" = "thunar.desktop";
      "text/html" = "${browser}.desktop";
      "text/plain" = "sublime_text.desktop";
      "video/mp4" = "mpv.desktop";
      "x-scheme-handler/http" = "${browser}.desktop";
      "x-scheme-handler/https" = "${browser}.desktop";
    };
    xdg.configFile."mimeapps.list".force = true;
  };
}
