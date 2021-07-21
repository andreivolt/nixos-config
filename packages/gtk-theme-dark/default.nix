{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "gtk-theme-dark";
  src = ./src;
  installPhase = ''
    mkdir -p $out/share/themes
    cp -r * $out/share/themes
  '';
}
