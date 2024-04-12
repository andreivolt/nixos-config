{ installApplication, fetchurl }:

installApplication rec {
  name = "superwhisper";
  version = "latest";
  sourceRoot = "superwhisper.app";
  src = fetchurl rec {
    name = "superwhisper.dmg";
    url = "https://builds.superwhisper.com/latest/superwhisper.dmg";
    sha256 = "sha256-ROhR+Gy6HeuRokE82W3ogfo5uRto0KCpSSS8tvU76Ho=";
  };
  description = "Superwhisper Description";
  homepage = "Superwhisper Homepage URL";
}
