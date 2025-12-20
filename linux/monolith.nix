{ config, lib, pkgs, inputs, ... }:

let
  user = "andrei";
  monolithDir = "/home/${user}/dev/monolith";
  monolith = inputs.monolith.packages.${pkgs.system};
  monolithEnvFile = config.sops.templates."monolith.env".path;
in
{
  home-manager.users.${user} = { config, pkgs, ... }: {

    # User CLI (mono command + aliases)
    home.packages = [ monolith.commands ];

    systemd.user.services.monolith = {
      Unit = {
        Description = "Monolith Clojure daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = monolithDir;
        EnvironmentFile = monolithEnvFile;

        # Pass through Hyprland socket path
        PassEnvironment = [ "HYPRLAND_INSTANCE_SIGNATURE" ];

        # Runtime deps (mpv, ffmpeg, clojure, jdk, coreutils, etc.)
        # TDLib native libs need openssl, zlib, libstdc++
        Environment = [
          "PATH=${monolith.runtime-deps}/bin"
          "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib:${pkgs.zlib}/lib:${pkgs.stdenv.cc.cc.lib}/lib"
          "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
        ];

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
