{ config, lib, pkgs, ... }:

let
  vpn = with (import ./credentials.nix).vpn; {
    config = conf;
    autoStart = false;
    authUserPass = { inherit username password; };
  };

in {
  environment.systemPackages = with pkgs; let
    whatismyip = pkgs.stdenv.mkDerivation rec {
      name = "whatismyip";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        ${pkgs.dnsutils}/bin/dig +short myip.opendns.com @resolver1.opendns.com
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [
    whatismyip
  ];

  networking = {
    enableIPv6 = false;
    hostName = builtins.getEnv "HOST";

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

      extraConfig = ''
        address=/test/127.0.0.1
      '';
    };

    openvpn.servers.default = vpn;
  };
}
