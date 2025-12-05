{
  home-manager.sharedModules = [
    {
      xdg.configFile."aria2/aria2.conf".text = ''
        file-allocation=none
        seed-time=0
      '';
    }
  ];
}
