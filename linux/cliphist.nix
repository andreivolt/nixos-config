# Clipboard history with cliphist
{ pkgs, ... }:
{
  home-manager.sharedModules = [{
    services.cliphist = {
      enable = true;
      allowImages = true;
    };

    # Clipboard history menu (rofi UI)
    home.packages = [
      (pkgs.writeShellScriptBin "rofi-clip" ''
        cliphist list | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Clipboard" | cliphist decode | wl-copy
      '')
    ];
  }];
}