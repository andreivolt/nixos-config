{ pkgs ? import <nixpkgs> {}, stdenv, zlib, lib, qt5, saneBackends, makeWrapper, fetchurl }:

stdenv.mkDerivation rec {
  name = "zprint-bin-${version}";
  version = "1.0.2";

  src = pkgs.fetchurl {
    url = "https://github.com/kkinnear/zprint/releases/download/1.1.2/zprintl-1.1.2";
    sha256 = "1paiyi77icqc9r6mvax72qjapnr9wgf14lv2gjklzspqx3x702am";
  };

  dontConfigure = true;
  dontBuild = true;
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

  # meta = with stdenv.lib; {
  #   homepage = https://github.com/kkinnear/zprint;
  #   description = "Library to reformat Clojure and Clojurescript source code and s-expressions ";
  #   license = licenses.free;
  #   platforms = platforms.linux;
  # };
}

# zprint = pkgs.stdenv.mkDerivation rec {
#   name = "zprint";
#   src = pkgs.fetchurl {
#     url = "https://github.com/kkinnear/zprint/releases/download/0.4.10/zprintl-0.4.10";
#     sha256 = "0iab2gvynb0njhr2vy26li165sc2v6p5pld7ifp6jlf7yj3yr4gl";
#   };
#   unpackPhase = ":";
#   dontStrip = true;
#   preFixup =
#     let rpath = with pkgs; lib.makeLibraryPath [ zlib ];
#     in ''
#       patchelf \
#         --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
#         --set-rpath "${rpath}" \
#         $out/bin/zprint
#     '';
#   installPhase = "mkdir -p $out/bin && cp $src $out/bin/zprint && chmod +x $out/bin/zprint";
# };
