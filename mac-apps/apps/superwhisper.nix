{ installApplication, fetchurl }:

installApplication rec {
  name = "superwhisper";
  version = "latest";
  sourceRoot = "superwhisper.app";
  src = fetchurl rec {
    name = "superwhisper.dmg";
    url = "https://builds.superwhisper.com/latest/superwhisper.dmg";
    sha256 = "sha256-Xm6tvmmf/wnZ72zRdiukwE8AntDHKxY+drug/4eEzlI=";
  };
  description = "Superwhisper Description";
  homepage = "Superwhisper Homepage URL";
}
