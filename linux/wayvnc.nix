{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = [pkgs.wayvnc];

    systemd.user.services.wayvnc = {
      Unit = {
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        ConditionEnvironment = ["WAYLAND_DISPLAY"];
      };
      Service.ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wayvnc}/bin/wayvnc $(${pkgs.tailscale}/bin/tailscale ip -4)'";
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
