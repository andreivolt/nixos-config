{
  home-manager.users.avo.programs.zathura = {
    enable = true;

    config = ''
      set incremental-search true
      set window-title-basename true
    '';
  };
}
