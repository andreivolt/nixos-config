{ installApplication, fetchurl }:

installApplication rec {
  name = "IntelliBar";
  version = "0.16.0";
  sourceRoot = "IntelliBar.app";
  src = fetchurl rec {
    name = "IntelliBar-${version}-arm64.dmg";
    url = "https://github.com/intellibar/main/releases/download/0.16.0/IntelliBar-0.16.0-arm64.dmg";
    sha256 = "c2156922796183a6213fefce8109f2c4c67b0c09e61874521f0ea9c43aeb0cde";
  };
  description = "Intelligent toolbar for macOS";
  homepage = "https://github.com/intellibar/main";
}
