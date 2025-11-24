{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    # ./hardware-configuration.nix  # Machine-specific, not tracked in git
    ../shared/cursor.nix
    ../shared/dnsmasq.nix
    ../shared/fonts.nix
    ../shared/gnupg.nix
    ../shared/direnv.nix
    ./insync.nix
    ../shared/moreutils-without-parallel.nix
    ./mpv.nix
    ../shared/nix.nix
    ../shared/tor.nix
    ../shared/zsh-nix-completion.nix
    ./adb.nix
    ./battery-monitor.nix
    ./brother-printer.nix
    ./brother-scanner.nix
    ./cliphist.nix
    ./docker.nix
    ./dropdown.nix
    ./fingerprint.nix
    ./flashfocus.nix
    ./gnome-keyring.nix
    ./gtk.nix
    ./ipv6-disable.nix
    ./libvirt.nix
    ./lowbatt.nix
    ./mako.nix
    ./networkmanager.nix
    ./nixos-rebuild-summary.nix
    ./nm-applet.nix
    ./pipewire.nix
    ./qt.nix
    ./rclone.nix
    ./swaybg.nix
    # ./sway  # Uncomment to use Sway
    ./hyprland  # Using Hyprland
    ./swaync.nix
    ./thinkpad.nix
    ./trayscale.nix
    ./waybar.nix
    ./v4l2loopback.nix
    ./wayvnc.nix
    ./xdg-portals.nix
  ];

  networking.hostName = builtins.getEnv "HOSTNAME";
  system.stateVersion = "23.11";

  boot.loader.timeout = 0;
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/sda" ];  # Placeholder - adjust per machine
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };  # Placeholder
  # boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";

  console.keyMap = "fr";
  console.earlySetup = true;
  console.font = "ter-132n";
  console.packages = [pkgs.terminus_font];

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;

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
    imports = [ ../shared/rust-script-warmer.nix ];
    
    home.stateVersion = "23.11";
    home.enableNixpkgsReleaseCheck = false;
    nixpkgs.config = config.nixpkgs.config;
    nixpkgs.overlays = config.nixpkgs.overlays;

    home.packages = (import "${inputs.self}/packages.nix" pkgs) ++ (import ./packages.nix pkgs);

    programs.zsh = {
      enable = true; # TODO
      enableCompletion = false;
      initExtra = "source ~/.config/zsh/rc.zsh";
    };

    # services.clipman.enable = true;  # Replaced by cliphist
    services.playerctld.enable = true;
    services.wob.enable = true;

    # Vicinae launcher daemon
    programs.vicinae = {
      enable = true;
      systemd = {
        enable = true;
        autoStart = true;
        target = "graphical-session.target";
      };
      useLayerShell = true;
    };

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
