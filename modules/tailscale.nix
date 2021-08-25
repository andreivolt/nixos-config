{ pkgs, config, ... }:

{
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [ tailscale ];

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
