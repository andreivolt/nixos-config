{ pkgs, ... }:

let
  cursor-theme = "Adwaita";
  cursor-size = 48;
in {
  home-manager.users.avo = {
    home.packages = with pkgs; [ gnome.adwaita-icon-theme ];
    home.sessionVariables = {
      XCURSOR_THEME = cursor-theme;
      XCURSOR_SIZE = cursor-size;
    };
    # fix sway cursor size
    wayland.windowManager.sway.config.seat."*" = {
      xcursor_theme = "${cursor-theme} ${toString cursor-size}";
    };

    gtk.cursorTheme.name = cursor-theme;
    gtk.cursorTheme.size = cursor-size;
  };
}
