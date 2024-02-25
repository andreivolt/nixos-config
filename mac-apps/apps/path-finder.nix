{ installApplication, fetchurl }:

installApplication rec {
  name = "PathFinder";
  version = "latest";
  sourceRoot = "PathFinder.app";
  src = fetchurl rec {
    name = "PathFinder.dmg";
    url = "https://get.cocoatech.com/PathFinder.dmg";
    sha256 = "4738fad569deef4dabddcbee30822fe0fc4a5cf97c18c8df677036891fd9bce8";
  };
  description = "File management application";
  homepage = "https://cocoatech.com/";
}
