{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.cifs-utils ];

  # Resolve Freebox router admin to LAN IP
  services.dnsmasq.settings.address = [ "/mafreebox.freebox.fr/192.168.1.254" ];

  fileSystems."/mnt/freebox" = {
    device = "//mafreebox.freebox.fr/Disque dur";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=5s"
      "guest"
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
    ];
  };
}
