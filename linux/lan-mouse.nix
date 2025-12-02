{ config, pkgs, lib, ... }:

let
  hostname = config.networking.hostName;

  # Peer configurations using Tailscale MagicDNS hostnames
  peerConfigs = {
    watts = {
      direction = "right";
      peer = "riva";
    };
    riva = {
      direction = "left";
      peer = "watts";
    };
  };

  hasPeerConfig = peerConfigs ? ${hostname};
  peerConfig = peerConfigs.${hostname} or null;
in {
  # Open UDP port for lan-mouse
  networking.firewall.allowedUDPPorts = [ 4242 ];

  # Enable uinput for emulating input devices (required for lan-mouse receiver)
  hardware.uinput.enable = true;
  users.users.andrei.extraGroups = [ "input" ];

  # Lan Mouse config and service
  home-manager.users.andrei = { config, pkgs, ... }: {
    # Generate lan-mouse config file (only if hostname has peer config)
    xdg.configFile = lib.optionalAttrs hasPeerConfig {
      "lan-mouse/config.toml".text = ''
        port = 4242

        [${peerConfig.direction}]
        hostname = "${peerConfig.peer}"
        activate_on_startup = true
      '';
    };

    # Lan Mouse systemd user service (daemon mode, no GUI)
    systemd.user.services.lan-mouse = {
      Unit = {
        Description = "Lan Mouse - mouse/keyboard sharing";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse daemon";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
