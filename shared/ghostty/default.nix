{pkgs, lib, ...}:
let
  colors = import ../colors.nix;
  colorSettings = import ./colors.nix { inherit colors; };
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
          font-size = 13;

          adjust-cell-height = -4;
          adjust-font-baseline = 0;
          adjust-cell-width = "-12%";

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
        } // colorSettings;
      };
    }
  ];
}
