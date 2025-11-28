{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./vars.nix
  ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.hypridle.enable = true;

  programs.hyprlock.enable = true;

  environment.systemPackages = with pkgs; [
    hyprshot
  ] ++ (with inputs.hyprland.packages.${pkgs.system}; [
    hyprland-qtutils
  ]) ++ (with inputs.hyprland-plugins.packages.${pkgs.system}; [
    hyprexpo
    hyprbars
  ]);
}
