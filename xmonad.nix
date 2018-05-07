let
  avo-xmonad = import ./xmonad-config;

in {
  fileSystems."xmonad-config" = {
    device = "/etc/nixos/xmonad-config";
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.config/xmonad";
  };

  home-manager.users.avo
    .xsession.windowManager.command = "${avo-xmonad}/bin/xmonad";
}
