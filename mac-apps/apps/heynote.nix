{ installApplication, fetchurl }:

installApplication rec {
  name = "Heynote";
  version = "1.4.2";
  sourceRoot = "Heynote.app";
  src = fetchurl rec {
    name = "Heynote_${version}_universal.dmg";
    url = "https://github.com/heyman/heynote/releases/download/v${version}/Heynote_1.4.2_universal.dmg";
    sha256 = "ef0f7c66bae857d030662504ff68854bd1d2948dbf58e9322441be4c1df89f16";
  };
  homepage = "https://github.com/heyman/heynote";
}
