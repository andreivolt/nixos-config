self: pkgs: rec {

docx2txt = with pkgs; stdenv.mkDerivation rec {
  name = "docx2txt";
  version = "1.4";

  src = fetchurl {
    url = "http://downloads.sourceforge.net/${name}/${name}-${version}.tgz";
    sha256 = "06vdikjvpj6qdb41d8wzfnyj44jpnknmlgbhbr1w215420lpb5xj";
  };

  buildInputs = [ perl unzip ];
  dontBuild = true;
  installPhase =
    ''
      mkdir -p $out/{bin,etc}

      cp docx2txt.config $out/etc
      cp docx2txt.pl $out/bin/docx2txt

      substituteInPlace $out/bin/docx2txt --replace /usr/bin/unzip ${unzip}/bin/unzip
    '';
};

}
