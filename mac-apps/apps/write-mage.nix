{ installApplication, fetchurl }:

installApplication rec {
  name = "WriteMage";
  version = "latest";
  sourceRoot = "WriteMage.app";
  src = fetchurl rec {
    name = "WriteMage.dmg";
    url = "https://magic.writemage.com/WriteMage.dmg";
    sha256 = "d60eeaafa6a64c91d5b61d449151481c9ced5611ff2db0d28f9552b49330ff39";
  };
}
