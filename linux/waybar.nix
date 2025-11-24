{ config, lib, pkgs, ... }:

{
  # Enable waybar with systemd integration
  programs.waybar = {
    enable = true;
    # Waybar will read its config from ~/.config/waybar/config and style.css
  };
}