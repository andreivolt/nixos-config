self: pkgs: rec {

mpris-ctl = with pkgs; stdenv.mkDerivation rec {
  name = "mpris-ctl";

  src = fetchFromGitHub {
    owner = "mariusor";
    repo = "mpris-ctl";
    rev = "c920c16507b3bd83e4edfe00b372008035509c63";
    sha256 = "1hy5js09r64jflyh51cm8h90bria9234yj8hnxi98cdpydys3agy";
  };

  buildInputs = with pkgs; [ ];

  # installPhase = ''
  # '';
};

}
