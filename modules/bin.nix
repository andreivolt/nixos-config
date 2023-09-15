{ stdenv }:

stdenv.mkDerivation rec {
  name = "avo-bin";

  src = ./.;

  installPhase = ''
    mkdir $out
    cp -r $src $out/bin
  '';
}
