{ pkgs, ... }:

{
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
  in [ whatismyip ];
}
