{pkgs, ...}: {
  home-manager.sharedModules = [{
    systemd.user.services.volume = {
      Unit = {
        Description = "Volume daemon with event batching";
        PartOf = ["hyprland-session.target"];
        After = ["wob.service"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.andrei.volume}/bin/volume daemon";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = ["hyprland-session.target"];
    };
  }];
}
