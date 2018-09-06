{ config, lib, pkgs, ... }:

{
  networking = {
    enableIPv6 = false;

    hostName = builtins.getEnv "HOSTNAME";

    wireless = {
      enable = true;
      networks =
        lib.mapAttrs'
          (name: value:
            lib.nameValuePair name (lib.listToAttrs [(lib.nameValuePair "psk" value)]))
          (import ./credentials.nix).wifi;
    };
  };

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
    };

    dnsmasq = {
      enable = true;

      servers = [ "8.8.8.8" "8.8.4.4" ];

      extraConfig = "address=/test/127.0.0.1";
    };

    openvpn.servers.default = with (import ./credentials.nix).vpn; {
      config = conf;
      autoStart = false;
      authUserPass = { inherit username password; };
    };
  };
}
