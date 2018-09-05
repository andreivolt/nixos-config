{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; let
    irc = pkgs.stdenv.mkDerivation rec {
      name = "irc";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        ${pkgs.emacs}/bin/emacsclient \
            --socket-name irc \
            --create-frame --frame-parameters '((name . "irc"))' -e '(+avo/irc)' \
            --no-wait
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [ irc ];
}
