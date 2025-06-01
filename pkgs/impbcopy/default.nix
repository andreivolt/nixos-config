{
  clang,
  darwin,
  fetchgit,
  lib,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "impbcopy";
  version = "1.0";

  src = fetchgit {
    url = "https://gist.github.com/mwender/49609a18be41b45b2ae4.git";
    rev = "01b2dd549ea57b92350c29c8a7ff0cdffe78e546";
    hash = "sha256-xgO6GJUxZ2Nd2EwKlHJMYHE2QQoklyoZlK3owEtrO5Y=";
  };

  buildInputs =
    [clang]
    ++ (with darwin.apple_sdk_11_0.frameworks; [Foundation AppKit Cocoa]);

  buildPhase = ''
    clang -Wall -O2 -ObjC \
      -framework Foundation -framework AppKit \
      -o impbcopy impbcopy.m
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp impbcopy $out/bin/
  '';

  meta = with lib; {
    description = "A command-line tool to copy images to the clipboard";
    platforms = platforms.darwin;
  };
}
