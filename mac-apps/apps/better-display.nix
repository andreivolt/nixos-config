{ installApplication, fetchurl }:

installApplication rec {
  name = "BetterDisplay";
  version = "2.1.3";
  sourceRoot = "BetterDisplay.app";
  src = fetchurl rec {
    name = "BetterDisplay-${version}.dmg";
    url = "https://github.com/waydabber/BetterDisplay/releases/download/v${version}/BetterDisplay-${version}.dmg";
    sha256 = "1bfbcc0b16ad810c933e9ae5f503caa59615943275b7b84060b5b5e4721d5926";
  };
  description = "Display management tool";
  homepage = "https://github.com/waydabber/BetterDisplay";
}
