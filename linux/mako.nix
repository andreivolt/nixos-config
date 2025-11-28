{
  home-manager.users.andrei.services.mako = {
    enable = true;
    settings = {
      width = 800;
      height = 9999;
      background-color = "#000000CC";
      font = "${(import ../shared/theme.nix).font.family} 28";
      layer = "overlay";
      border-size = 1;
      border-color = "#00ff00";
      margin = "20";
      padding = "20";
      "app-name=tidal-hifi".default-timeout = 5000;
      "app-name=Spotify".default-timeout = 5000;
    };
  };
}
