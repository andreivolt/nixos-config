{ config, lib, pkgs, ... }:

{
  # systemd.user.services.ircEmacsDaemon = let
  #   makeEmacsDaemon = import ../util/make-emacs-daemon.nix;
  #   credentials = import ../private/credentials.nix;
  # in
  #   (makeEmacsDaemon { name = "irc"; inherit config pkgs; })
  #   // {
  #     environment.FREENODE_USERNAME = credentials.freenode.username;
  #     environment.FREENODE_PASSWORD = credentials.freenode.password;
  #   };

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
  in [
    irc
  ];
}
