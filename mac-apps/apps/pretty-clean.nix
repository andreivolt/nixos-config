{ installApplication, fetchurl }:

installApplication rec {
  name = "PrettyClean";
  version = "0.1.38";
  sourceRoot = "PrettyClean.app";
  src = fetchurl rec {
    name = "PrettyClean_${version}_aarch64.dmg";
    url = "https://downloads.jmotor.org/prettyclean/v0.1.38/darwin-aarch64/PrettyClean_0.1.38_aarch64.dmg";
    sha256 = "sha256-GDLW/9vg/L/+NcOy9qxAMefozpOnxWQSSRSIjr+0OIU=";
  };
}
