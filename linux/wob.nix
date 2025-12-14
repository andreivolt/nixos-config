# wob - Wayland Overlay Bar for volume/brightness indicators
{...}:
let
  colors = import ../shared/colors.nix;
  # Strip # prefix from hex color for wob (expects RRGGBB not #RRGGBB)
  stripHash = s: builtins.substring 1 6 s;
in {
  home-manager.sharedModules = [{
    services.wob = {
      enable = true;
      settings = {
        "" = {
          anchor = "bottom";
          margin = 100;
          height = 30;
          width = 300;
          border_size = 1;
          border_offset = 2;
          bar_padding = 2;
          background_color = "${stripHash colors.aurora.background}88";
          border_color = "${stripHash colors.aurora.foreground}99";
          bar_color = "${stripHash colors.aurora.foreground}cc";
          overflow_background_color = "${stripHash colors.aurora.background}88";
          overflow_border_color = "${stripHash colors.accent.primary}99";
          overflow_bar_color = "${stripHash colors.accent.primary}cc";
        };
      };
    };
  }];
}
