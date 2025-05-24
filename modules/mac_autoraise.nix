{pkgs, ...}: let
  autoraise = pkgs.callPackage ../pkgs/autoraise {experimental_focus_first = true;};
in {
  launchd.user.agents.autoRaise.serviceConfig = {
    ProgramArguments = [
      "${autoraise}/bin/AutoRaise"
      "-delay"
      "3" # 100ms delay
      "-altTaskSwitcher"
      "true"
    ];
    RunAtLoad = true;
    KeepAlive = true;
  };
}
