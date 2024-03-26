{ fetchurl
, stdenv
, python3
}:

stdenv.mkDerivation rec {
  name = "json2nix";
  src = fetchurl {
    url = "https://gist.githubusercontent.com/andreivolt/c0ccee3868def8778fb8fb6436489630/raw/1d47fde8d2f9b3029ed8535518bb32af497edcba/json2nix";
    sha256 = "sha256-IacRsDQTX60H5SoXIcAVAfGdJ41YBATXbMJGD61xb7Y";
  };
  buildInputs = [ python3 ];
  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
    chmod +x $out/bin/${name}
    patchShebangs $out/bin/${name}
  '';
}

