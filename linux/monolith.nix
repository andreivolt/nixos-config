{ config, lib, pkgs, ... }:

let
  user = "andrei";
  monolithDir = "/home/${user}/dev/monolith";
  envFile = "/home/${user}/.config/env";
  # Socket in XDG_RUNTIME_DIR (proper place for runtime sockets)
  # Service creates /run/user/1000/monolith/monolith.sock
in
{
  home-manager.users.${user} = { config, pkgs, ... }: {

    systemd.user.services.monolith = {
      Unit = {
        Description = "Monolith Clojure daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = monolithDir;
        EnvironmentFile = envFile;

        # Pass through Hyprland socket path
        PassEnvironment = [ "HYPRLAND_INSTANCE_SIGNATURE" ];

        ExecStart = "${pkgs.clojure}/bin/clojure -M:run";
        Restart = "on-failure";
        RestartSec = 5;

        # Minimal isolation (JVM needs flexibility)
        NoNewPrivileges = true;
        ProtectControlGroups = true;
        ProtectKernelTunables = true;
        RestrictSUIDSGID = true;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  # Firewall: allow fileserver port for Chromecast to fetch audio
  networking.firewall.allowedTCPPorts = [ 8766 ];
}
