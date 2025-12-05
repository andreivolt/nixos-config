{pkgs, inputs, ...}: let
  autoraise = pkgs.callPackage "${inputs.self}/pkgs/autoraise" {experimental_focus_first = true;};
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
