{ config, pkgs, lib, ... }:

let
  # Machine-specific peer configuration
  isAsahi = config.networking.hostName == "asahi";

  # Mac (Asahi) IP - ThinkPad connects to this
  macIP = "192.168.1.195";
  # ThinkPad IP - Mac connects to this
  thinkpadIP = "192.168.1.171";
in {
  # Open UDP port for lan-mouse
  networking.firewall.allowedUDPPorts = [ 4242 ];
  # Open TCP port for Input Leap (Synergy fork)
  networking.firewall.allowedTCPPorts = [ 24800 ];

  # Enable uinput for emulating input devices (required for lan-mouse receiver)
  hardware.uinput.enable = true;
  users.users.andrei.extraGroups = [ "input" ];

  # Lan Mouse config and service
  home-manager.users.andrei = { config, pkgs, ... }: {
    # Generate lan-mouse config file
    xdg.configFile."lan-mouse/config.toml".text = if isAsahi then ''
      # Asahi (Mac) config - ThinkPad is to the left
      port = 4242

      [left]
      hostname = "thinkpad"
      ips = ["${thinkpadIP}"]
      activate_on_startup = true
    '' else ''
      # ThinkPad config - Mac is to the right
      port = 4242

      [right]
      hostname = "mac"
      ips = ["${macIP}"]
      activate_on_startup = true
    '';

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
