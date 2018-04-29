{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    virt-viewer
  ];

  environment.variables = {
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  virtualisation.libvirtd.enable = true;

  home-manager.users.avo.xdg.configFile = {
    "virt-viewer/settings".text = lib.generators.toINI {} {
      virt-viewer = {
        ask-quit = false;
      };
    };
  };
}
