{pkgs, ...}: let
  cursor-theme = "Adwaita";
  cursor-size = 24;
in {
  home-manager.users.andrei = {
    home.packages = [pkgs.adwaita-icon-theme];

    home.sessionVariables = {
      XCURSOR_THEME = cursor-theme;
      XCURSOR_SIZE = cursor-size;
    };

    home.pointerCursor = {
      name = cursor-theme;
      size = cursor-size;
      package = pkgs.adwaita-icon-theme;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
