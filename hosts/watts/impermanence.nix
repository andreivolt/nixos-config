{ ... }:
{
  imports = [ ../../shared/impermanence-base.nix ];

  environment.persistence."/persist".directories = [
    "/var/lib/systemd/backlight"
    "/var/lib/libvirt"
    "/var/lib/lxd"
    "/var/lib/machines"
    "/var/lib/roon-idle-inhibit"
    { directory = "/var/lib/roon-server"; user = "roon-server"; group = "roon-server"; mode = "u=rwx,g=rx,o="; }
  ];
}
