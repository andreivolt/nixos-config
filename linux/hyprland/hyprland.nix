{ config, lib, pkgs, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.hypridle.enable = true;

  programs.hyprlock.enable = true;

  environment.systemPackages = with pkgs; [
    hyprshot
  ] ++ (with inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}; [
    hyprland-qtutils
  ]) ++ (with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
    hyprexpo
    hyprbars
  ]);
}
