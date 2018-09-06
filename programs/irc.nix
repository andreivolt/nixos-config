{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; let
    irc = pkgs.stdenv.mkDerivation rec {
      name = "irc";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        exec &>/dev/null

        ${pkgs.emacs}/bin/emacs \
          --name irc
          --load ~/.emacs.d/irc.el &

        disown
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [ irc ];
}
