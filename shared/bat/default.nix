{pkgs, ...}: {
  home-manager.sharedModules = [
    {
      programs.bat = {
        enable = true;
        config = {
          style = "header-filename,grid";
          theme = "Aurora";
          wrap = "character";
        };
        themes = {
          Aurora = {
            src = ./.;
            file = "aurora.tmTheme";
          };
        };
      };
    }
  ];
}
