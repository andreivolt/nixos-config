{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = [
      pkgs.wlvncc
      (pkgs.callPackage ../pkgs/vnc {})
    ];

    systemd.user.services.wayvnc = {
      Unit = {
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        ConditionEnvironment = ["WAYLAND_DISPLAY"];
      };
      Service.ExecStart = "${pkgs.wayvnc}/bin/wayvnc -o eDP-1 127.0.0.1";
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
