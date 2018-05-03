{ pkgs, ... }:

let
  theme = import ./themes/challenger-deep.nix;

  myFonts = {
    proportional = "Abel";
    monospace = "Source Code Pro";
    defaultSize = 10;
  };

in {
  imports = [
    ./redshift.nix
    ./rofi.nix
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
    home.sessionVariables
      .QT_AUTO_SCREEN_SCALE_FACTOR = 1;

    services = {
      unclutter.enable = true;

      dunst = {
        enable = true;
        settings = import ./dunstrc.nix {
          inherit theme;
          font = myFonts.proportional;
        };
      };
    };

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
      windowManager.command = "~/.local/bin/xmonad";
      initExtra =
        let
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
            while sleep 1; do
            systemctl --user --state active list-units mainEmacsDaemon.service && {
              (sleep 3 && ${pkgs.emacs}/bin/emacsclient --socket-name main --create-frame --no-wait) &
              break
            }
            done

            ${pkgs.qutebrowser}/bin/qutebrowser &
          '';

        in ''
          ${cursor}
          ${monitorLayout}
          ${wallpaper}
          ${startupPrograms}
        '';
    };

    xdg.configFile = {
      "xmobar/xmobarrc".text =
        import ./xmobarrc.nix {
          inherit theme;
          font = myFonts.proportional;
        };

      "xmobar/bin/online-indicator" = {
        text = with theme; ''
          color=$(is-online && echo '${green}' || echo '${red}')
          symbol=$(is-online && echo ﯱ || echo ﯱ)

          echo "<fc=$color>$symbol</fc>"
        '';
        executable = true;
      };
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
