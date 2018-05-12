let
  avo-xmonad = import ../xmonad-config;

in {
  home-manager.users.avo
    .xsession.windowManager.command = "${avo-xmonad}/bin/xmonad";

  fileSystems."xmonad-config" = {
    device = "/etc/nixos/xmonad-config";
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.config/xmonad";
  };
}
