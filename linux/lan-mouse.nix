{ config, pkgs, lib, ... }:

{
  # Open UDP port for lan-mouse
  networking.firewall.allowedUDPPorts = [ 4242 ];
}
