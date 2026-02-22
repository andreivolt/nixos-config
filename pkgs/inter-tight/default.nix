{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "inter-tight";
  version = "4.0";

  srcs = [
    (fetchurl {
      name = "InterTight.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/main/ofl/intertight/InterTight%5Bwght%5D.ttf";
      sha256 = "0vwbz3qijx88a7pcj91z4dizhfvpqpv7vpmsr8qc5wsdnvf766xq";
    })
    (fetchurl {
      name = "InterTight-Italic.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/main/ofl/intertight/InterTight-Italic%5Bwght%5D.ttf";
      sha256 = "1qjv73jak73c1dl4qj4m8q576v6hk1rlr34va9c0cmnjqgqfvlqm";
    })
  ];

  sourceRoot = ".";
  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    for src in $srcs; do
      install -m644 "$src" $out/share/fonts/truetype/
    done
  '';

  meta = {
    description = "Inter Tight - tighter spacing variant of the Inter font family";
    homepage = "https://fonts.google.com/specimen/Inter+Tight";
    license = lib.licenses.ofl;
  };
}
