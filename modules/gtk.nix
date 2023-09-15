let
  font = "Ubuntu";
in {
  home-manager.users.avo.gtk = {
    enable = true;
    theme.name = "Breeze-Dark";
    # theme = {
    #   name = "dark";
    #   package = pkgs.callPackage ../packages/gtk-theme-dark {  };
    # };
    # font.name = "${font} 10";
  };
}
