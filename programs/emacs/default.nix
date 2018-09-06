{ config, lib, pkgs, ... }:

with pkgs; let
  emacs =
    stdenv.lib.overrideDerivation
      pkgs.emacs
      (attrs: {
        nativeBuildInputs =
          attrs.nativeBuildInputs ++
          (with pkgs; [
            aspell aspellDicts.en aspellDicts.fr
            w3m ]);});

  emacs-wrapper = stdenv.mkDerivation rec {
    name = "emacs";

    src = [(pkgs.writeScript name ''
      #!/usr/bin/env bash

      exec &>/dev/null

      ${emacs}/bin/emacs \
        --load ~/.emacs.d/prog.el \
        $@ &

      disown
    '')];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
    '';
  };

in {
  environment.systemPackages = [ (lowPrio emacs) emacs-wrapper ];

  fileSystems."emacs" = {
    device = builtins.toString ./emacs.d;
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.emacs.d";
  };

}
