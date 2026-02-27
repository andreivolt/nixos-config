# On-screen AZERTY keyboard for tablet mode
# Auto-shows on text input focus via input-method-v2
# Show/hide via SIGUSR2/SIGUSR1 (used by autorotate + bindswitch)
{ pkgs, config, lib, ... }: {
  environment.systemPackages = [ pkgs.andrei.osk ];

  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.osk = {
      Unit = {
        Description = "On-screen AZERTY keyboard";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.andrei.osk}/bin/osk --hidden";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "hyprland-session.target" ];
      };
    };
  };
}
