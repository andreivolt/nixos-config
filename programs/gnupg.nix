{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ gnupg ];

  home-manager.users.avo
    .home.sessionVariables.GNUPGHOME = with config.home-manager.users.avo;
      "${xdg.configHome}/gnupg";

  fileSystems."gnupg" = {
    device = "/etc/nixos/private/gnupg";
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.config/gnupg";
  };
}
