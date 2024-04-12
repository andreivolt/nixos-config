{ installApplication, fetchurl }:

installApplication rec {
  name = "ChatTab";
  version = "latest";
  sourceRoot = "ChatTab.app";
  src = fetchurl rec {
    name = "ChatTab.dmg";
    url = "https://lessstorage.blob.core.windows.net/chattab/ChatTab.dmg";
    sha256 = "sha256-96jlpQ0JPIUjdhSzh+ltGfTIS34BAwVofEKKOh+qK4Q=";
  };
}
