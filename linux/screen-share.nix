# Screen sharing with WebRTC
{
  config,
  pkgs,
  lib,
  ...
}: {
  home-manager.users.andrei = {pkgs, ...}: {
    home.packages = [
      pkgs.andrei.screen-share
    ];
  };
}
