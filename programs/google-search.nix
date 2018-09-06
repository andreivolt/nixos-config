{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; let
    google-search = stdenv.mkDerivation rec {
      name = "google-search";

      src = [(writeScript name ''
        ${surfraw}/bin/surfraw google *
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [ google-search surfraw ];
}
