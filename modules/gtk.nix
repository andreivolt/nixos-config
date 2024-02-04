let
  font = "Ubuntu";
in {
  home-manager.users.andrei.gtk = {
    enable = true;
    theme.name = "Breeze-Dark";
    # theme = {
    #   name = "dark";
    #   package = "${builtins.getEnv "HOME"}/drive/nix-packages/gtk-theme-dark" { };
    # };
    # font.name = "${font} 10";
  };
}
