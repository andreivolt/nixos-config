{ config, pkgs, lib, ... }:

{
  # Open UDP port for lan-mouse
  networking.firewall.allowedUDPPorts = [ 4242 ];
  # Open TCP port for Input Leap (Synergy fork)
  networking.firewall.allowedTCPPorts = [ 24800 ];

  # Enable uinput for emulating input devices (required for lan-mouse receiver)
  hardware.uinput.enable = true;
  users.users.andrei.extraGroups = [ "input" ];

  # Lan Mouse systemd user service
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.lan-mouse = {
      Unit = {
        Description = "Lan Mouse - mouse/keyboard sharing";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse --frontend gtk";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
