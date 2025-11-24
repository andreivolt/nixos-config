{ config, lib, pkgs, ... }:

{
  # Install network manager applet
  environment.systemPackages = [ pkgs.networkmanagerapplet ];

  # Enable network manager applet service
  home-manager.users.andrei = { config, pkgs, ... }: {
    services.network-manager-applet.enable = true;
  };
}