{
  home-manager.users.avo.programs.t = {
    enable = true;

    username = "andreivolt";
    credentials = (import ../private/credentials.nix).twitter;
  };
}
