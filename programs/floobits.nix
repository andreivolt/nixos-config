{
  home-manager.users.avo
    .home.file.".floorc.json".text = builtins.readFile ../private/floobits/.floorc.json;
}
