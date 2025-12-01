# Base NixOS configuration shared between linux and asahi
{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ../shared/cursor.nix
    ../shared/dnsmasq.nix
    ../shared/fonts.nix
    ../shared/gnupg.nix
    ../shared/direnv.nix
    ../shared/moreutils-without-parallel.nix
    ../shared/nix.nix
    ../shared/tor.nix
    ../shared/zsh-nix-completion.nix
    ./brother-printer.nix
    ./brother-scanner.nix
    ./cliphist.nix
    ./docker.nix
    ./dropdown.nix
    ./eww.nix
    ./gnome-keyring.nix
    ./greetd.nix
    ./gtk.nix
    ./hyprland
    ./lowbatt.nix
    ./networkmanager.nix
    ./nm-applet.nix
    ./pipewire.nix
    ./qt.nix
    ./swaybg.nix
    ./swaync.nix
    ./trayscale.nix
    ./v4l2loopback.nix
    ./waybar.nix
    ./xdg-portals.nix
    ./chromium.nix
    ./dolphin.nix
  ];

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
    extraGroups = ["wheel" "video" "input"];
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

  
}
