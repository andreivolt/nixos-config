{ pkgs, ... }:

let autoraise = pkgs.callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/autoraise" { experimental_focus_first = true; };
in {
  launchd.user.agents.autoRaise.serviceConfig = {
    ProgramArguments = [
      "${autoraise}/bin/AutoRaise"
      "-delay" "0"
      "-altTaskSwitcher" "true"
    ];
    RunAtLoad = true;
    KeepAlive = true;
  };
}
