{ config, lib, pkgs, ... }:

let
  emacs = pkgs.stdenv.lib.overrideDerivation
            pkgs.emacs
            (attrs: {
              nativeBuildInputs =
                attrs.nativeBuildInputs ++
                (with pkgs; [
                  aspell aspellDicts.en aspellDicts.fr
                  w3m ]);});

in {
  environment.systemPackages = [ emacs ];
}
