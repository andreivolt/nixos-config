{ installApplication, fetchurl }:

installApplication rec {
  name = "Kit";
  version = "2.0.42";
  sourceRoot = "Kit.app";
  src = fetchurl rec {
    name = "Kit-macOS-${version}-arm64.dmg";
    url = "https://github.com/johnlindquist/kitapp/releases/download/v${version}/Kit-macOS-2.0.42-arm64.dmg";
    sha256 = "5caf4603580e538a08eba2b63ad9968f76bd680a37e10f7458a8575dd14f3f19";
  };
  description = "Scripting environment for developers";
  homepage = "https://github.com/johnlindquist/kitapp";
}
