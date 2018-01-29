{ config, pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;

  users.users.avo.extraGroups = [ "libvirtd" ];

  environment.variables."LIBVIRT_DEFAULT_URI" = "qemu:///system";
}
