{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = [pkgs.wayvnc];

    systemd.user.services.wayvnc = {
      Unit = {
        PartOf = ["sway-session.target"];
        After = ["netns@tailscale0.service" "sway-session.target"];
        BindsTo = ["netns@tailscale0.service"];
        ConditionEnvironment = ["WAYLAND_DISPLAY"];
        JoinsNameSpaceOf = "netns@tailscale0.service";
      };
      Service.PrivateNetwork = true;
      Service.ExecStart = "${pkgs.wayvnc}/bin/wayvnc";
      Install.WantedBy = ["sway-session.target"];
    };
  };
}
