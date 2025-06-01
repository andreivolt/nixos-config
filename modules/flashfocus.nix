{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = [pkgs.flashfocus];

    systemd.user.services.flashfocus = {
      Unit = {
        BindsTo = ["sway-session.target"];
        Wants = ["sway-session.target"];
        After = ["sway-session.target"];
      };

      Service = {
        ExecStart = "${pkgs.flashfocus}/bin/flashfocus --time 250";
        Path = [pkgs.procps];
      };

      Install.WantedBy = ["sway-session.target"];
    };
  };
}
