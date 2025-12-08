{ config, pkgs, lib, ... }:

let
  hostname = config.networking.hostName;

  # Certificate fingerprints for each host (sha256 of lan-mouse.pem)
  # Must be lowercase - lan-mouse's generate_fingerprint() outputs lowercase hex
  fingerprints = {
    riva = "c3:ef:f5:55:e9:d8:05:b5:42:6b:d9:ed:7d:89:f7:b5:8d:6f:a6:db:42:04:04:71:b8:9c:8e:dc:0f:b7:26:f6";
    watts = "ec:5f:c5:b1:cb:69:0a:18:ba:3a:fd:ac:c2:03:58:e2:4b:24:02:09:54:f6:cf:74:ff:c1:9f:58:56:e8:99:06";
  };

  # Peer configurations using Tailscale IPs
  peerConfigs = {
    watts = {
      position = "right";
      peer = "riva";
      ip = "100.64.0.2";
    };
    riva = {
      position = "left";
      peer = "watts";
      ip = "100.64.0.3";
    };
  };

  peerConfig = peerConfigs.${hostname} or null;

  configToml = pkgs.writeText "lan-mouse-config.toml" ''
    port = 4242

    [[clients]]
    hostname = "${peerConfig.peer}"
    ips = ["${peerConfig.ip}"]
    port = 4242
    position = "${peerConfig.position}"
    activate_on_startup = true

    [authorized_fingerprints]
    "${fingerprints.${peerConfig.peer}}" = "${peerConfig.peer}"
  '';
in {
  # Open UDP port for lan-mouse
  networking.firewall.allowedUDPPorts = [ 4242 ];

  # Enable uinput for emulating input devices (required for lan-mouse receiver)
  hardware.uinput.enable = true;
  users.users.andrei.extraGroups = [ "input" ];

  home-manager.users.andrei = { config, pkgs, ... }: {
    # Lan Mouse systemd user service (daemon mode, no GUI)
    systemd.user.services.lan-mouse = {
      Unit = {
        Description = "Lan Mouse - mouse/keyboard sharing";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        # Config from nix store, cert from persistent home
        ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse --config ${configToml} --cert-path %h/.config/lan-mouse/lan-mouse.pem daemon";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
