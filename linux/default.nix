{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    # ./hardware-configuration.nix  # Machine-specific, not tracked in git
    ./disk-config.nix  # Disk configuration with disko
    ./impermanence.nix  # Impermanence setup
    ./users-persist.nix  # User-specific persistence configuration
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
    ./eww.nix
    ./fkey-remap.nix
    ./fingerprint.nix
    ./flashfocus.nix
    ./gnome-keyring.nix
    ./greetd.nix
    ./gtk.nix
    ./ipv6-disable.nix
    ./libvirt.nix
    ./lowbatt.nix
    ./networkmanager.nix
    ./nixos-rebuild-summary.nix
    ./nm-applet.nix
    ./pipewire.nix
    ./qt.nix
    ./rclone.nix
    ./roon-server.nix
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

  # Boot loader configuration is now in disk-config.nix
  # Filesystem configuration is handled by disko and impermanence modules

  console.keyMap = "fr";
  console.earlySetup = true;
  console.font = "ter-132n";
  console.packages = [pkgs.terminus_font];

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  users.users.andrei = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDicuhnKrdUp8G8JZH+jEZWpTTCYO5zQ7I30an07AfS8VP734swtLVc6Hwl5wZ37R8mbusOccw2VsUAZYQBWBZs4tqmzHxAT2fIPo22xgXggdgyb6uXcC7/pvb6BiCkIYawAU3Rbw7Le295HC3g/SkJMlpiKlJllyyzjyP3JISBYKMJdO6PJxsfUHJDG5LCA1/hMyjKjPT5QO6/Go4usEgThcvMxJiV9bVL16PAuENnFLCA3avj9cfk/5VN/HUG1f3SVFQytivFPIb54ke3tgr7Z/a2MZKj+GcTpmxoFLlsmmz6uPSRE+eB8QzpRlO+rny9YmHhKmt10tdEU/KITQAlBLfowE5fJIZIjlui70pWgh62GFDO/30RaJXkUSD8pYUwzzcdAWVbMZsyJ1A7O79deryp8ZFBAUJsiaw2KhCCOLcVFv06n2wUyUZjPE2u1NduWQLZLP/Vnzi1JRYhims8RzN/UyA24uY3XbKZ+jV8kUuoHATiNiI62/CJExABhOk= andrei@mac"
    ];
  };

  programs.mosh.enable = true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
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
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--operator=andrei"];
  };
  services.upower.enable = true;

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";
  environment.variables.LC_TIME = "C.UTF-8";

  

  home-manager.users.andrei = {pkgs, ...}: {
    imports = [
      ../shared/rust-script-warmer.nix
      inputs.vicinae.homeManagerModules.default
    ];
    
    home.stateVersion = "23.11";
    home.enableNixpkgsReleaseCheck = false;
    nixpkgs.config = config.nixpkgs.config;
    nixpkgs.overlays = config.nixpkgs.overlays;

    home.packages = (import "${inputs.self}/packages.nix" pkgs) ++ (import ./packages.nix pkgs);

    programs.zsh = {
      enable = true; # TODO
      enableCompletion = false;
      initContent = "source ~/.config/zsh/rc.zsh";
    };

    # services.clipman.enable = true;  # Replaced by cliphist
    services.playerctld.enable = true;
    services.wob.enable = true;
    services.vicinae = {
      enable = true;
      autoStart = true;
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
