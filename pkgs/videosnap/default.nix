{ darwin
, fetchFromGitHub
, lib
, stdenv
, swiftPackages
}:

stdenv.mkDerivation rec {
  pname = "videosnap";
  version = "0.0.9";

  src = fetchFromGitHub {
    owner = "matthutchinson";
    repo = "videosnap";
    rev = "v${version}";
    sha256 = "sha256-3jjUyqJTXnvRxz0/+oqtGagvM7W8PVLPgPnpvQwIrW4=";
  };

  buildInputs =
    with darwin.apple_sdk.frameworks; [ CoreMedia AVFoundation CoreMediaIO ]
      ++ [ swiftPackages.Foundation ];

  NIX_CFLAGS_COMPILE = "-Wno-deprecated-declarations";

  buildPhase = ''
    mkdir build
    cc -framework CoreMedia -framework AVFoundation -framework CoreMediaIO -framework Foundation \
       -o build/videosnap videosnap/videosnap.m
  '';

  installPhase = ''
    install -D -m 755 build/videosnap $out/bin/videosnap
    install -D -m 644 videosnap/videosnap.1 $out/share/man/man1/videosnap.1
  '';

  meta = with lib; {
    description = "Simple command line tool to record video and audio from any attached capture device";
    homepage = "https://github.com/matthutchinson/videosnap";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
