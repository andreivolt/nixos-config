{
  environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";

  virtualisation.libvirtd.enable = true;

  users.users.andrei.extraGroups = ["libvirtd"];
}
