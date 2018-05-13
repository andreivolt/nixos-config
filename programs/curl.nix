{
  home-manager.users.avo.programs.curl = {
    enable = true;

    config = ''
      follow
      globoff
      silent
      user-agent mozilla
    '';
  };
}

