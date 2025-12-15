{
  home-manager.sharedModules = [
    {
      xdg.configFile."wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
    }
  ];
}
