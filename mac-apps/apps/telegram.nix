{ installApplication, fetchurl }:

installApplication rec {
  name = "Telegram";
  version = "latest";
  sourceRoot = "Telegram.app";
  src = fetchurl rec {
    name = "Telegram.dmg";
    url = "https://osx.telegram.org/updates/Telegram.dmg";
    sha256 = "sha256-hy7hnLP4fwhS46E9+tXgFRi9wO/GWlAFLi56S15Pcug=";
  };
  description = "Messaging application";
  homepage = "https://telegram.org";
}
