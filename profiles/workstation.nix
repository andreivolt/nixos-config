# Workstation/Desktop configuration for Linux
# Include this module for desktop/graphical environments
# For headless servers, use base.nix only
{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    # Desktop hardware & peripherals
    ../linux/brother-printer.nix
    ../linux/brother-scanner.nix
    ../linux/lowbatt.nix
    ../linux/networkmanager.nix
    ../linux/v4l2loopback.nix

    # Services
    ../linux/tor.nix

    # GUI components
    ../shared/cursor.nix
    ../shared/fonts.nix
    ../linux/cliphist.nix
    ../linux/dropdown.nix
    ../linux/eww.nix
    ../linux/gnome-keyring.nix
    ../linux/greetd.nix
    ../linux/gtk.nix
    ../linux/hyprland
    ../linux/nm-applet.nix
    ../linux/pipewire.nix
    ../linux/qt.nix
    ../linux/swaybg.nix
    ../linux/swaync.nix
    ../linux/trayscale.nix
    ../linux/waybar.nix
    ../linux/xdg-portals.nix
    ../linux/chromium.nix
    ../linux/dolphin.nix
    ../linux/kbd-backlight-idle.nix
  ];

  # GUI-specific hardware
  hardware.graphics.enable = true;

  # GUI-related services
  services.devmon.enable = true;
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;

  # Battery monitoring for laptops
  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };
}
