# Shared home-manager config for linux systems
{ config, inputs }:

{pkgs, ...}: {
  imports = [
    ./desktop-entries.nix
    ./hyprland/pin-auto.nix
    ./mime-apps.nix
    ./rofi.nix
    ./xdg-places
    ./zathura.nix
  ];

  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config = config.nixpkgs.config;
  nixpkgs.overlays = config.nixpkgs.overlays;

  home.packages =
    (import "${inputs.self}/packages/core.nix" pkgs)
    ++ (import "${inputs.self}/packages/linux.nix" pkgs)
    ++ (import "${inputs.self}/packages/workstation.nix" pkgs)
    ++ (import "${inputs.self}/packages/gui.nix" pkgs);

  services.playerctld.enable = true;

  xdg.enable = true;
  xdg.userDirs.enable = true;
}
