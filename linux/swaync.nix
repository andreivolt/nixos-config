{ config, lib, pkgs, ... }:

{
  # Install swaync package
  environment.systemPackages = [ pkgs.swaync ];

  # SwayNotificationCenter service
  home-manager.users.andrei = { config, pkgs, ... }: {
    services.swaync = {
      enable = true;
      # Will use config from ~/.config/swaync/ if it exists
    };
  };
}