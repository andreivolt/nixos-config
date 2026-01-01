{pkgs, lib, ...}:
let
  colors = import ../colors.nix;
  aurora = colors.aurora;
in {
  home-manager.sharedModules = [
    {
      programs.ghostty.package =
        if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
      xdg.configFile = {
        "ghostty/shaders/cursor_blaze.glsl".source = ./cursor_blaze.glsl;
        "ghostty/shaders/cursor_blaze_no_trail.glsl".source = ./cursor_blaze_no_trail.glsl;
      };

      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;

        settings = {
          font-family = "Pragmasevka Nerd Font Light";
          font-family-italic = "Pragmasevka Nerd Font Light Italic";
          font-family-bold = "Pragmasevka Nerd Font";
          font-family-bold-italic = "Pragmasevka Nerd Font Italic";
          font-thicken = true;
          font-size = 16;

          adjust-cell-height = -8;
          adjust-font-baseline = 0;
          adjust-cell-width = "-12%";

          foreground = aurora.foreground;
          background = aurora.background;
          cursor-color = aurora.cursor;
          cursor-text = aurora.cursorText;
          selection-background = aurora.selection.background;
          selection-foreground = aurora.selection.foreground;

          palette = [
            "0=${aurora.normal.black}"
            "1=${aurora.normal.red}"
            "2=${aurora.normal.green}"
            "3=${aurora.normal.yellow}"
            "4=${aurora.normal.blue}"
            "5=${aurora.normal.magenta}"
            "6=${aurora.normal.cyan}"
            "7=${aurora.normal.white}"
            "8=${aurora.bright.black}"
            "9=${aurora.bright.red}"
            "10=${aurora.bright.green}"
            "11=${aurora.bright.yellow}"
            "12=${aurora.bright.blue}"
            "13=${aurora.bright.magenta}"
            "14=${aurora.bright.cyan}"
            "15=${aurora.bright.white}"
            "16=${aurora.extended.color16}"
            "17=${aurora.extended.color17}"
          ];

          minimum-contrast = 1;
          window-padding-x = 8;
          window-padding-y = 8;
          background-opacity = 0.75;
          background-blur-radius = 15;
          window-save-state = "always";
          window-vsync = false;
          macos-non-native-fullscreen = true;
          macos-window-shadow = false;
          window-decoration = false;
          cursor-style = "bar";
          mouse-hide-while-typing = true;
          confirm-close-surface = false;
          alpha-blending = "linear-corrected";
          window-colorspace = "display-p3";
          auto-update = "off";
          cursor-click-to-move = true;
          gtk-single-instance = true;

          keybind = [
            "shift+enter=text:\\x0a"
          ];
        };
      };
    }
  ];
}
