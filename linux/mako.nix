{
  home-manager.users.andrei.services.mako = {
    enable = true;
    width = 800;
    height = 9999;
    backgroundColor = "#000000CC";
    font = "${(import ../shared/theme.nix).font.family} 28";
    layer = "overlay";
    borderSize = 1;
    borderColor = "#00ff00";
    margin = "20";
    padding = "20";
    extraConfig = ''
      [app-name=tidal-hifi]
      default-timeout=5000

      [app-name=Spotify]
      default-timeout=5000
    '';
  };
}
