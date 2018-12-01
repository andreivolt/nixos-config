{
 fileSystems."/mnt/shield" = {
   device = "//192.168.1.29/internal";
   fsType = "cifs";
   options = [
     "x-systemd.automount" "noauto"
     "x-systemd.idle-timeout=60" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"
     "username=andrei.volt" "password=fo-chou-knot"
     "vers=1.0"
   ];
 };
}
