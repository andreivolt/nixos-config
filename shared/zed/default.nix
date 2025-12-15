{
  home-manager.sharedModules = [
    {
      xdg.configFile = {
        "zed/settings.json".source = ./settings.json;
        "zed/keymap.json".source = ./keymap.json;
      };
    }
  ];
}
