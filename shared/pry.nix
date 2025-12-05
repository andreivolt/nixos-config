{
  home-manager.sharedModules = [
    {
      xdg.configFile."pry/pryrc".source = ./pry/pryrc;
    }
  ];
}
