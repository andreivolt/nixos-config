{pkgs, ...}: {
  home-manager.sharedModules = [
    {
      programs.htop = {
        enable = true;
        package = pkgs.htop-vim;
        settings = {
          show_program_path = false;
        };
      };
    }
  ];
}
