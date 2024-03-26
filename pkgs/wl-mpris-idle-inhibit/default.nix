{ buildRustPackage
, fetchFromGitHub
}:

buildRustPackage rec {
  name = "wl-mpris-idle-inhibit";
  version = "1ee2598fe8863b75569b43b003f2eaea7b8936be";

  src = fetchFromGitHub {
    owner = "andreivolt";
    repo = "wl-mpris-idle-inhibit";
    rev = version;
    hash = "sha256-9Tl2bBZ2WzjJvAbewk+7qX11HzeQPIFwAqOO7BFx2gY=";
  };

  cargoVendorDir = "vendor";
  cargoSha256 = null;
}
