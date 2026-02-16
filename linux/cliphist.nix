# Clipboard history with cliphist
{ pkgs, ... }:
{
  home-manager.sharedModules = [{
    services.cliphist = {
      enable = true;
      allowImages = true;
    };
  }];
}
