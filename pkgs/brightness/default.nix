{ darwin
, fetchFromGitHub
, lib
, stdenv
}:

let target = "brightness.arm64";
in stdenv.mkDerivation rec {
  pname = "brightness";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "nriley";
    repo = pname;
    rev = "1.2";
    hash = "sha256-FCkCHs0h1uf/h5rUr6FBftnoEFLMWnEUCG6NWuzUTso=";
  };

  buildInputs = with darwin.apple_sdk.frameworks; [
    ApplicationServices
    CoreDisplay
    DisplayServices
    IOKit
  ];

  buildPhase = ''
    make ${target}
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${target} $out/bin/brightness
  '';

  meta = with lib; {
    description = "Command-line display brightness control for macOS";
    homepage = "https://github.com/nriley/brightness";
    license = licenses.bsd2;
    platforms = platforms.darwin;
  };
}
