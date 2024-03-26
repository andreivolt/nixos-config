{ fetchurl
, stdenv
}:

stdenv.mkDerivation rec {
  name = "anypaste";

  src = fetchurl {
    url = "https://anypaste.xyz/sh";
    sha256 = "sha256-w0My8b0scQ3/hgGqeBK1X0qKcgjwWgMqwPLgohGUCRI=";
  };

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
    chmod +x $out/bin/${name}
  '';
}
