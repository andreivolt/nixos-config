{ installApplication, fetchurl }:

installApplication rec {
  name = "PrefEdit";
  version = "latest";
  sourceRoot = "PrefEdit.app";
  src = ../dmgs/PrefEdit.dmg;
  description = "";
  homepage = "";
}
