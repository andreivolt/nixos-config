{ pkgs, ... }:

let
  theme = import ./themes/challenger-deep.nix;

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
    find-cursor
    setroot
    seturgent
    wmctrl xdotool xnee
    xrandr-invert-colors
    copyq xclip xsel
    polybar

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
          "Xcursor.size"  = 40;
          "Xcursor.theme" = "Adwaita";
        };
      in
           colors
        // cursor;

    xsession = {
      enable = true;
      initExtra = let
        cursor = ''
          ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr 40
        '';

        monitorLayout = "${pkgs.avo-scripts}/bin/monitor-layout";

        wallpaper = let wallpaperPath = "~/doc/wallpapers/matterhorn.jpg"; in ''
          ${pkgs.setroot}/bin/setroot -z ${wallpaperPath} -z ${wallpaperPath} -z ${wallpaperPath}
        '';

        startupPrograms = ''
          until systemctl --user --state running list-units mainEmacsDaemon.service; do sleep 1; done &&
            ${pkgs.emacs}/bin/emacsclient --socket-name main --create-frame &

          ${pkgs.qutebrowser}/bin/qutebrowser &
        '';
      in ''
        ${cursor}
        ${monitorLayout}
        ${wallpaper}
        ${startupPrograms}
      '';
    };
  };
}
