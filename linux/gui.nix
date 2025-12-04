# GUI-specific imports for Linux desktops
# Include this module for desktop/graphical environments
# For headless servers, use base.nix only
{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ../shared/cursor.nix
    ../shared/fonts.nix
    ./cliphist.nix
    ./dropdown.nix
    ./eww.nix
    ./gnome-keyring.nix
    ./greetd.nix
    ./gtk.nix
    ./hyprland
    ./nm-applet.nix
    ./pipewire.nix
    ./qt.nix
    ./swaybg.nix
    ./swaync.nix
    ./trayscale.nix
    ./waybar.nix
    ./xdg-portals.nix
    ./chromium.nix
    ./dolphin.nix
    ./kbd-backlight-idle.nix
  ];

  # GUI-specific hardware
  hardware.graphics.enable = true;

  # GUI-related services
  services.devmon.enable = true;
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;
}
