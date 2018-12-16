{ pkgs, ... }:

{
  systemd.user.services.isync = {
    serviceConfig.Type = "oneshot";
    path = [ pkgs.wrapped.isync ];
    script = "mbsync main";
  };

  systemd.user.timers.isync = {
    wantedBy = [ "default.target" ];
    timerConfig = { Unit = "isync.service"; OnCalendar = "*:*:0/30"; };
  };
}
