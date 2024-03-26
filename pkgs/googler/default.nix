{ fetchFromGitHub
, stdenv
}:

stdenv.mkDerivation {
  name = "googler";

  src = fetchFromGitHub {
    owner = "oksiquatzel";
    repo = "googler";
    rev = "82012aa78db8df898153a8d3843dad3e6d3fa7c8";
    hash = "sha256-Ay4OQNIuSyMDe+cbTCh9FrrmbByEOek1mn51bI/8sd0=";
  };

  installPhase = ''
    make install PREFIX=$out
  '';
}
