{ pkgs, ... }:

let
  theme = import ./themes/challenger-deep.nix;

  myFonts = {
    proportional = "Abel";
    monospace = "Source Code Pro";
    defaultSize = 10;
  };

  avo-xmonad = import ./xmonad-config;

in {
  imports = [
    ./dunst.nix
    ./redshift.nix
    ./rofi.nix
    ./xmobar.nix
  ];

  environment.systemPackages = with pkgs; [
    find-cursor
    setroot
    seturgent
    wmctrl xdotool xnee
    xrandr-invert-colors
    copyq xclip xsel
    polybar
    avo-xmonad

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
    home.sessionVariables
      .QT_AUTO_SCREEN_SCALE_FACTOR = 1;

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

        fonts = {
          "Xft.dpi" = 180;
          # "*.font"        = "xft:${myFonts.monospace}:size=${toString myFonts.defaultSize}";
        };

        cursor = {
          "Xcursor.size"  = 40;
          "Xcursor.theme" = "Adwaita";
        };
      in
           colors
        // fonts
        // cursor;


    xsession = {
      enable = true;
      windowManager.command = "${avo-xmonad}/bin/xmonad";
      initExtra = let
        cursor = ''
          ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr 40
        '';

        monitorLayout = ''
          ${pkgs.xorg.xrandr}/bin/xrandr \
            --output DP-4 --auto --primary \
            --output DP-0 --auto --above DP-4 \
            --output DP-2 --auto --left-of DP-4 --rotate left
        '';

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

  services.compton = {
    enable = true;

    shadow = true;
    shadowOffsets = [ (-15) (-15) ];
    shadowOpacity = "0.7";
    # shadowExclude = [
    #   ''
    #     !(XMONAD_FLOATING_WINDOW ||
    #       (_NET_WM_WINDOW_TYPE@[0]:a = "_NET_WM_WINDOW_TYPE_DIALOG") ||
    #       (_NET_WM_STATE@[0]:a = "_NET_WM_STATE_MODAL"))
    #   ''
    # ];
    extraOptions = ''
      blur-background = true;
      #blur-background-frame = true;
      #blur-background-fixed = false;
      #blur-background-exclude = [
      #  "class_g = 'slop'";
      #];
      blur-kern = "11,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
      clear-shadow = true;
    '';
  };

  fonts = {
    fontconfig = {
      ultimate.enable = false;
      defaultFonts = with myFonts; {
        monospace = [ monospace ];
        sansSerif = [ proportional ];
      };
    };
    enableCoreFonts = true;
    fonts = with pkgs; [
      emacs-all-the-icons-fonts
      font-awesome-ttf
      google-fonts
      hack-font
      hasklig
      iosevka-custom
      material-icons
      nerdfonts
      overpass
      powerline-fonts
      terminus_font
      ubuntu_font_family
      vistafonts
    ];
  };
}
