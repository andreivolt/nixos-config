{
  home-manager.sharedModules = [
    {
      programs.bat = {
        enable = true;
        config = {
          style = "header-filename,grid";
          theme = "base16";
          wrap = "character";
        };
      };
    }
  ];
}
