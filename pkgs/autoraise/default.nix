{
  alternative_task_switcher ? false,
  darwin,
  experimental_focus_first ? true,
  fetchurl,
  lib,
  old_activation_method ? false,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "AutoRaise";
  version = "4.7";

  src = fetchurl {
    url = "https://github.com/sbmpost/AutoRaise/archive/refs/tags/v${version}.tar.gz";
    sha256 = "sha256-ustWLc+RRcrRJkgsCVN0brrk0p+/+xHlk512mFAOGTk=";
  };

  buildInputs = with darwin.apple_sdk_11_0.frameworks; [
    AppKit
    ApplicationServices
    Carbon
    SkyLight
  ];

  preConfigure = let
    flags = lib.concatStringsSep " " [
      (lib.optionalString alternative_task_switcher "-DALTERNATIVE_TASK_SWITCHER")
      (lib.optionalString old_activation_method "-DOLD_ACTIVATION_METHOD")
      (lib.optionalString experimental_focus_first "-DEXPERIMENTAL_FOCUS_FIRST")
    ];
  in ''
    export CXXFLAGS="${flags}"
  '';

  prePatch = ''
    substituteInPlace AutoRaise.mm --replace 'kAXValueCGPointType' 'kAXValueTypeCGPoint'
    substituteInPlace AutoRaise.mm --replace 'kAXValueCGRangeType' 'kAXValueTypeCGRange'
    substituteInPlace AutoRaise.mm --replace 'kAXValueCGSizeType' 'kAXValueTypeCGSize'
    substituteInPlace Makefile --replace g++ clang++
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp AutoRaise $out/bin
  '';

  meta = with lib; {
    homepage = "https://github.com/sbmpost/AutoRaise";
    description = "A utility to automatically raise windows on mouse hover";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
