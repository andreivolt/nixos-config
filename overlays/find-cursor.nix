self: pkgs: rec {

find-cursor = with pkgs; stdenv.mkDerivation rec {
  name = "find-cursor";

  src = fetchFromGitHub {
    owner = "Carpetsmoker";
    repo = "find-cursor";
    rev = "a$efd2efe76dda50d0876c8c6861f6487f27b4ae";
    sha256 = "0fiv15mcxym17fqb51lyglfki91xca93z9dqn1cq84bj7ibqp1rv";
  };

  buildInputs = [ x11 ];
};

}
