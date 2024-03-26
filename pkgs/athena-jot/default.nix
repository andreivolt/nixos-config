{ fetchurl
, libarchive
, stdenv
}:

stdenv.mkDerivation rec {
  pname = "athena-jot";
  version = "9.4-0";

  src = fetchurl {
    url = "https://stuff.mit.edu/afs/athena/system/rhlinux/athena-9.4/SRPMS/athena-jot-9.4-0.src.rpm";
    sha256 = "sha256-zggK6eEDK8rqJq3cIWdhaaj4y7RgexS7qQp+KpvLdPg=";
  };

  nativeBuildInputs = [ libarchive ];

  unpackPhase = ''
    bsdtar -xf $src
    bsdtar -zxf athena-jot-9.4.tar.gz
    find
  '';

  sourceRoot = "./athena-jot-9.4";
}
