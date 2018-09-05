{ config, lib, pkgs, ... }:

{
  networking.firewall.allowedUDPPorts = [ 60001 ];

  environment.systemPackages = with pkgs; [ mosh ];
}
