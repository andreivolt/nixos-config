{ pkgs ? import <nixpkgs> {}, stdenv, zlib, lib, qt5, saneBackends, makeWrapper, fetchurl }:

stdenv.mkDerivation rec {
  name = "zprint-bin-${version}";
  version = "1.0.2";

  src = pkgs.fetchurl {
    url = "https://github.com/kkinnear/zprint/releases/download/1.1.2/zprintl-1.1.2";
    sha256 = "1paiyi77icqc9r6mvax72qjapnr9wgf14lv2gjklzspqx3x702am";
  };

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/zprint
    chmod +x $out/bin/zprint
  '';

  preFixup = let
    # we prepare our library path in the let clause to avoid it become part of the input of mkDerivation
    libPath = lib.makeLibraryPath [
      zlib
      stdenv.cc.cc.lib
    ];
  in ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      $out/bin/zprint
  '';
}
