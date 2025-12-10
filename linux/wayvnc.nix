{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = [pkgs.wayvnc];

    systemd.user.services.wayvnc = {
      Unit = {
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        ConditionEnvironment = ["WAYLAND_DISPLAY"];
      };
      Service.ExecStart = "${pkgs.wayvnc}/bin/wayvnc 127.0.0.1";
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
