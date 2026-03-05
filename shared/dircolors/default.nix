# Dircolors configuration - minimal palette (dirs/links/exec only)
{
  home-manager.sharedModules = [
    {
      home.file.".dir_colors".source = ./dir_colors;
    }
  ];
}
