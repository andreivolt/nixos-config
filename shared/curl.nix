{
  home-manager.sharedModules = [
    {
      xdg.configFile."curlrc".text = ''
        silent
      '';
    }
  ];
}
