{
  home-manager.users.avo
    .home.file.".netrc".text = builtins.readFile ./private/netrc;
}
