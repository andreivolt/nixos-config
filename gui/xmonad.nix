let
  avo-xmonad = import ./xmonad-config;

in {
  home-manager.users.avo
    .xsession.windowManager.command = "${avo-xmonad}/bin/xmonad";

  fileSystems."xmonad-config" = {
    device = builtins.toString ./xmonad-config;
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.config/xmonad";
  };
}
