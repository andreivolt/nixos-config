{ config, pkgs, ... }:

{
  imports = [
    ./wifi.nix
    ./privoxy.nix
    ./sshd.nix
  ];

  networking = {
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
    hostName = builtins.getEnv "HOST";
  };

  environment.systemPackages = with pkgs; [
    hostsblock
  ];
  # polipo

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
    };

    tor.client.enable = true;

    zerotierone.enable = true;

    dnsmasq = {
      enable = true;
      servers = [ "8.8.8.8" "8.8.4.4" ];

      extraConfig = ''
        address=/test/127.0.0.1
      '';
    };
  };
}
