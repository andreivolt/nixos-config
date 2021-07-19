{
  console.font = "latarcyrheb-sun32";

  programs.dconf.enable = true;

  home-manager.users.avo.dconf.settings = {
    "org/gnome/desktop/interface" = { scaling-factor = 2; };
  };
}
