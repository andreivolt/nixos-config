{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = [pkgs.wayvnc];

    systemd.user.services.wayvnc = {
      Unit = {
        PartOf = ["graphical-session.target"];
        After = ["netns@tailscale0.service" "graphical-session.target"];
        BindsTo = ["netns@tailscale0.service"];
        ConditionEnvironment = ["WAYLAND_DISPLAY"];
        JoinsNameSpaceOf = "netns@tailscale0.service";
      };
      Service.PrivateNetwork = true;
      Service.ExecStart = "${pkgs.wayvnc}/bin/wayvnc";
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
