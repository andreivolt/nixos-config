{ installApplication, fetchurl }:

installApplication rec {
  name = "Downie";
  version = "4.4653";
  sourceRoot = "Downie.app";
  src = fetchurl rec {
    name = "Downie_${version}.dmg";
    url = "https://software.charliemonroe.net/trial/downie/v4/Downie_4_4653.dmg";
    sha256 = "ae492cc0451155a08fe23aac29864d7cf7ba7ea95256472c882b1adbae21a737";
  };
  description = "Video downloader for macOS";
  homepage = "https://software.charliemonroe.net/downie/";
}
