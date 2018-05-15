{ lib, pkgs, ... }:

let
  theme = import ../themes/challenger-deep.nix;

in {
  imports = [
    ./compton.nix
    ./dunst.nix
    ./fonts.nix
    ./hdpi.nix
    ./redshift.nix
    ./rofi.nix
    ./xmobar.nix
    ./xmonad.nix
  ];

  environment.systemPackages = with pkgs; [
    copyq xclip xsel
    find-cursor
    polybar
    setroot
    seturgent
    wmctrl wmutils-core xdotool xnee
    xrandr-invert-colors

    # materia-theme
    # numix-gtk-theme
    # adapta-gtk-theme

    # qtstyleplugin-kvantum-qt4
    # qtstyleplugins
    # qtstyleplugin-kvantum
    # QT_QPA_PLATFORMTHEME=gtk2
    gnome3.adwaita-icon-theme
    # breeze-gtk breeze-qt5 qt5ct
    lxappearance
    arc-theme
    arc-icon-theme
  ];


  services.xserver = {
    enable = true;

    displayManager.auto = { enable = true; user = "avo"; };
    desktopManager.xterm.enable = false;

    # displayManager.sddm.enable = true;
    # windowManager.sway.enable = true;
    # https://github.com/waymonad/waymonad
  };


  home-manager.users.avo = {
    services.unclutter.enable = true;

    xresources.properties =
      let
        colors = with theme; {
          "*.background" = background; "*.foreground" = foreground;
          "*.color0"     = black;      "*.color8"     = gray;
          "*.color1"     = red;        "*.color9"     = lightRed;
          "*.color2"     = green;      "*.color10"    = lightGreen;
          "*.color3"     = yellow;     "*.color11"    = lightYellow;
          "*.color4"     = blue;       "*.color12"    = lightBlue;
          "*.color5"     = magenta;    "*.color13"    = lightMagenta;
          "*.color6"     = cyan;       "*.color14"    = lightCyan;
          "*.color7"     = white;      "*.color15"    = lightWhite;

          "*.borderColor" = background;
          "*.colorUL"     = white;
          "*.cursorColor" = foreground;
        };

        cursor = {
          "Xcursor.size"  = 60;
          "Xcursor.theme" = "Adwaita";
        };
      in
           colors
        // cursor;

    xsession = {
      enable = true;
      initExtra = let
        setMonitors = "${pkgs.avo-scripts}/bin/set-monitors";
        setWallpaper = "${pkgs.avo-scripts}/bin/set-wallpaper";
      in lib.concatStringsSep "\n" [
        setMonitors
        setWallpaper
      ];
    };
  };
}
