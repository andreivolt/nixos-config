# Dolphin file manager configuration for non-Plasma WMs (Hyprland, etc.)
# Fix file associations not working without Plasma
# https://github.com/NixOS/nixpkgs/issues/409986
{pkgs, ...}: {
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";
}
