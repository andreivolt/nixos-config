{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./shared/clojure.nix
    ./shared/cursor.nix
    ./shared/dnsmasq.nix
    ./shared/fonts.nix
    ./shared/gnupg.nix
    ./shared/insync.nix
    ./linux/adb.nix
    ./linux/brother-printer.nix
    ./linux/brother-scanner.nix
    ./linux/docker.nix
    ./linux/fingerprint.nix
    ./linux/flashfocus.nix
    ./linux/gnome-keyring.nix
    ./linux/gtk.nix
    ./linux/ipv6-disable.nix
    ./linux/libvirt.nix
    ./linux/lowbatt.nix
    ./linux/mako.nix
    ./linux/networkmanager.nix
    ./linux/nixos-rebuild-summary.nix
    ./linux/pipewire.nix
    ./linux/qt.nix
    ./linux/sway.nix
    ./linux/swayidle.nix
    ./linux/swaylock.nix
    ./linux/thinkpad-video.nix
    ./linux/v4l2loopback.nix
    ./linux/wayvnc.nix
    ./linux/xdg-portals.nix
    ./shared/moreutils-without-parallel.nix
    ./shared/mpv.nix
    ./shared/nix.nix
    ./shared/play-with-mpv.nix
    ./shared/tor.nix
    ./shared/zsh-nix-completion.nix
    <home-manager/nixos>
  ];

  networking.hostName = builtins.getEnv "HOSTNAME";

  nixpkgs.config.allowUnfree = true;

  boot.loader.timeout = 0;
  # boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";

  console.keyMap = "fr";
  console.earlySetup = true;
  console.font = "ter-132n";
  console.packages = [pkgs.terminus_font];

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;

  i18n.consoleKeyMap = "fr";
  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  users.users.andrei = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
  };

  programs.mosh.enable = true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.avahi = {
    enable = true;
    nssmdns = true;
  };
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

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";
  environment.variables.LC_TIME = "C.UTF-8";

  home-manager.users.andrei = {pkgs, ...}: {
    nixpkgs.overlays = config.nixpkgs.overlays;

    home.packages = (import "${inputs.self}/packages.nix" pkgs) ++ (import ./linux/packages.nix pkgs);

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
