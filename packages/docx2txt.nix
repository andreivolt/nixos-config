{ pkgs ? (import <nixpkgs> {})
, stdenv ? pkgs.stdenv
}:

stdenv.mkDerivation rec {
  name = "docx2txt";
  version = "1.4";
  buildInputs = with pkgs; [ perl unzip ];
  src = pkgs.fetchurl {
    url = "http://downloads.sourceforge.net/${name}/${name}-${version}.tgz";
    sha256 = "06vdikjvpj6qdb41d8wzfnyj44jpnknmlgbhbr1w215420lpb5xj";
  };
  dontBuild = true;
  installPhase =
    ''
      mkdir -p $out/{bin,etc}

      cp docx2txt.config $out/etc
      cp docx2txt.pl $out/bin/docx2txt

      substituteInPlace $out/bin/docx2txt --replace /usr/bin/unzip ${pkgs.unzip}/bin/unzip
    '';
}
