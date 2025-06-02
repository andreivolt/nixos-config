{ stdenv, lib, fetchFromGitHub, darwin }:

stdenv.mkDerivation rec {
  pname = "videosnap";
  version = "0.0.9";

  src = fetchFromGitHub {
    owner = "matthutchinson";
    repo = "videosnap";
    rev = "v${version}";
    sha256 = "sha256-3jjUyqJTXnvRxz0/+oqtGagvM7W8PVLPgPnpvQwIrW4=";
  };

  buildInputs = with darwin.apple_sdk.frameworks; [ Foundation AVFoundation CoreMedia CoreMediaIO ];

  buildPhase = ''
    runHook preBuild
    
    # Manual compilation since xcodebuild has issues in nix
    mkdir -p build
    cc -framework Foundation -framework AVFoundation -framework CoreMedia -framework CoreMediaIO \
       videosnap/Constants.m videosnap/main.m videosnap/videosnap.m \
       -o build/videosnap
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D -m 755 build/videosnap $out/bin/videosnap
    install -D -m 644 videosnap/videosnap.1 $out/share/man/man1/videosnap.1
    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple command line tool to record video and audio from any attached capture device";
    homepage = "https://github.com/matthutchinson/videosnap";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
