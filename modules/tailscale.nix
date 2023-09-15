{ pkgs, config, ... }:

{
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [ tailscale ];

  networking.firewall.checkReversePath = "loose";
  services.tailscale.useRoutingFeatures = "server";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
