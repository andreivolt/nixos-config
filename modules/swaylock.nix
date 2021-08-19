{ pkgs, ... }:

{
  systemd.user.services.swaylock = {
    before = [ "suspend.target" ];
    serviceConfig.Type = "forking";
    serviceConfig.ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
    environment.WAYLAND_DISPLAY = "wayland-1";
    wantedBy = [ "suspend.target" ];
    script = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
  };

  security.pam.services.swaylock.text = "auth include login";
}
