{ installApplication, fetchurl }:

installApplication rec {
  name = "Orion";
  version = "14.0";
  sourceRoot = "Orion.app";
  src = fetchurl rec {
    name = "Orion.dmg";
    url = "https://cdn.kagi.com/downloads/14_0/Orion.dmg";
    sha256 = "7f079223249dfcb0436bf9568c9d6f97ae76cca4925e1b8903221d2f5eb2da48";
  };
  description = "Web browser";
  homepage = "https://www.kagi.com";
}
