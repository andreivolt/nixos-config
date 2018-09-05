{ lib, pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;

  environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";

  users.users.avo.extraGroups = [ "libvirtd" ];


  environment.systemPackages = with pkgs; [ virt-viewer ];

  home-manager.users.avo
    .xdg.configFile."virt-viewer/settings".text = lib.generators.toINI {} {
      virt-viewer = {
        ask-quit = false;
      };
    };
}
