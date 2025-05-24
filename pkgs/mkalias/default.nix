{
  clang,
  darwin,
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation {
  name = "mkalias";

  buildInputs = [
    clang
    darwin.apple_sdk_11_0.frameworks.Foundation
  ];

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "mkalias";
    rev = "6c327ae1f9cbe6c82bd662d3498592cbb9807f59";
    sha256 = "sha256-L6bgCJ0fdiWmtlgTzDmTenTMP74UFUEqiDmE1+gg3zw=";
    fetchSubmodules = true;
  };

  buildPhase = ''
    clang -framework Foundation mkalias.m -o mkalias
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp mkalias $out/bin/
  '';
}
