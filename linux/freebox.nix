{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.cifs-utils ];

  fileSystems."/mnt/freebox" = {
    device = "//mafreebox.freebox.fr/Disque dur";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "guest"
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
    ];
  };
}
