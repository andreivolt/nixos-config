{
  lib,
  buildGoPackage,
  fetchgit,
}:
buildGoPackage rec {
  pname = "url-parser";
  version = "2017-07-17";
  rev = "823ca65eb0bd1c80c3499645cd04250ce5997092";

  goPackagePath = "github.com/herloct/${pname}";

  src = fetchgit {
    inherit rev;
    url = "https://${goPackagePath}";
    sha256 = "1w4664j4yycxrp237g9909clazaj2bys3x9q71ffpwxk91zjkmyw";
  };
}
