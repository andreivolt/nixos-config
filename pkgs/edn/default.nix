{
  fetchurl,
  stdenv,
}:
stdenv.mkDerivation rec {
  name = "edn";
  src = fetchurl {
    url = "https://gist.githubusercontent.com/andreivolt/6cbd58c9163ad5ac47e032b335898435/raw/convert.clj";
    sha256 = "sha256-3gZ38ICDWDKQamPvYuCL3yLR/l0+DrWe5iJYdu6TLYc=";
  };
  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
    chmod +x $out/bin/${name}
  '';
}
