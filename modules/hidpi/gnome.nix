{
  programs.dconf.enable = true;

  home-manager.users.andrei.dconf.settings = {
    "org/gnome/desktop/interface" = { scaling-factor = 2; };
  };

  environment.variables.GDK_SCALE = "2";
}
