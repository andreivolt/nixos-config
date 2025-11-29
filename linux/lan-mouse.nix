{ config, pkgs, lib, ... }:

{
  # Open UDP port for lan-mouse
  networking.firewall.allowedUDPPorts = [ 4242 ];
  # Open TCP port for Input Leap (Synergy fork)
  networking.firewall.allowedTCPPorts = [ 24800 ];
}
