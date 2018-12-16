{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ virt-viewer ];
  virtualisation.libvirtd.enable = true;
  environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";

  networking.bridges.br0.interfaces = [ "enp0s31f6" ];
  networking.firewall.trustedInterfaces = [ "br0" ];

  users.users.avo.extraGroups = [ "libvirt" ];
}
