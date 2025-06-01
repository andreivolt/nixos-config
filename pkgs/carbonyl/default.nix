{
  fetchurl,
  stdenv,
  unzip,
}:
stdenv.mkDerivation rec {
  pname = "carbonyl";
  version = "0.0.3";

  src = fetchurl {
    url = "https://github.com/fathyb/carbonyl/releases/download/v${version}/carbonyl.macos-arm64.zip";
    sha256 = "0r40v6pfmya1ppqk11abz33r9l6q6nzyw04xzyl99snqcir1kycc";
  };

  nativeBuildInputs = [unzip];

  unpackPhase = "unzip $src";

  installPhase = ''
    mkdir -p $out/bin $out/lib/carbonyl
    cp carbonyl-*/carbonyl $out/bin/
    cp carbonyl-*/*.{dat,bin,dylib} $out/lib/carbonyl/
  '';
}
