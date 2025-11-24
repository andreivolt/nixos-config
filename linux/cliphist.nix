{ config, lib, pkgs, ... }:

{
  # Install cliphist package
  environment.systemPackages = [ pkgs.cliphist ];

  # Cliphist clipboard history service
  home-manager.users.andrei = { config, pkgs, ... }: {
    services.cliphist = {
      enable = true;
      allowImages = true;  # Handles both text and images
    };
  };
}