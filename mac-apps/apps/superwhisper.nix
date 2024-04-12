{ installApplication, fetchurl }:

installApplication rec {
  name = "superwhisper";
  version = "latest";
  sourceRoot = "superwhisper.app";
  src = fetchurl rec {
    name = "superwhisper.dmg";
    url = "https://builds.superwhisper.com/latest/superwhisper.dmg";
    sha256 = "sha256-YjK3MuZqek8iKxuUFfUMrDxj9OGxb1p+hWmCjKizsg4=";
  };
  description = "Superwhisper Description";
  homepage = "Superwhisper Homepage URL";
}
