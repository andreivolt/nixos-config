{
  console.font = "latarcyrheb-sun32";
  # user font in initrd
  console.earlySetup = true;

  # # use maximum resolution in systemd-boot
  # boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";

  programs.dconf.enable = true;

  home-manager.users.avo.dconf.settings = {
    "org/gnome/desktop/interface" = { scaling-factor = 2; };
  };
}
