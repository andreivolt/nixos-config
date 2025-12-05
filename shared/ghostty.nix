{
  home-manager.sharedModules = [
    {
      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;

        settings = {
          font-family = "IosevkaTerm NFM Light";
          font-family-italic = "IosevkaTerm NFM Light Italic";
          font-family-bold = "IosevkaTerm NFM";
          font-family-bold-italic = "IosevkaTerm NFM Italic";
          font-thicken = true;
          font-size = 16;

          adjust-cell-height = -8;
          adjust-font-baseline = 0;
          adjust-cell-width = "-12%";

          # Aurora theme
          foreground = "#ffffff";
          background = "#000000";
          cursor-color = "#ddd0f4";
          cursor-text = "#211c2f";
          selection-background = "#3f4060";
          selection-foreground = "#e7d3fb";

          palette = [
            "0=#070510"
            "1=#ff5874"
            "2=#addb67"
            "3=#ffcb65"
            "4=#be9af7"
            "5=#FD9720"
            "6=#A1EFE4"
            "7=#645775"
            "8=#443d60"
            "9=#ec5f67"
            "10=#d7ffaf"
            "11=#fbec9f"
            "12=#6690c4"
            "13=#ffbe00"
            "14=#54CED6"
            "15=#e7d3fb"
            "16=#8a6e2b"
            "17=#a8834a"
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
            "shift+enter=text:\n"
          ];
        };
      };
    }
  ];
}
