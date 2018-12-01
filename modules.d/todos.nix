{ config, pkgs, ... }:

{
  systemd.user.services.todos = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.avo.todos ];
    script = "source ${config.system.build.setEnvironment} && todos_server";
    restartTriggers = [ pkgs.avo.todos ];
    serviceConfig.Restart = "always";
  };

  systemd.user.services.insync-todos = {
    serviceConfig.Type = "oneshot";
    path = [ pkgs.insync ];
    script = "insync force_sync %h/todos";
  };

  systemd.user.timers.insync-todos = {
    wantedBy = [ "default.target" ];
    timerConfig = { Unit = "insync-todos.service"; OnCalendar = "*:*:0/10"; };
  };

  systemd.user.services.todos-lib = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.avo.todos-lib ];
    script = "source ${config.system.build.setEnvironment} && todos-lib_server";
    serviceConfig.Restart = "always";
  };
}
