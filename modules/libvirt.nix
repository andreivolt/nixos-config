{
  environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";

  users.users.avo.extraGroups = [ "libvirtd" ];

  virtualisation.libvirtd.enable = true;
}
