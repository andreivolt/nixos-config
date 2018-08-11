
{ config, pkgs, ... }:

{
  services.openvpn.servers.default = let credentials = import ../private/credentials.nix; in {
    config = "config /etc/nixos/private/openvpn-conf.ovpn";
    autoStart = false;
    authUserPass = with credentials.vpn; { inherit username password; };
  };
}
