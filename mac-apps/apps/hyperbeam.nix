{ installApplication, fetchurl }:

installApplication rec {
  name = "Hyperbeam";
  version = "0.21.0";
  sourceRoot = "Hyperbeam.app";
  src = fetchurl {
    url = "https://cdn.hyperbeam.com/Hyperbeam-${version}.dmg";
    sha256 = "sha256-nPGPwjPvnxNq2n9NCiyT+8rivXh/qAtp0X9ItHnxBBI=";
  };
}
