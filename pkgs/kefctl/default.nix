{
  nixpkgs ? import <nixpkgs> {},
  perl ? nixpkgs.perl,
  fetchFromGitHub ? nixpkgs.fetchFromGitHub,
  stdenv ? nixpkgs.stdenv,
}:
stdenv.mkDerivation {
  pname = "kefctl";
  version = "1.1.7";
  buildInputs = [perl];
  src = fetchFromGitHub {
    owner = "andreivolt";
    repo = "kefctl";
    rev = "698624410b955fa9f5968748f28c8501f0f71864";
    sha256 = "1nafhbrhm6b42s97g98q1ac6r2a9mj3b19wnbk9hfvdhc3ahl6wp";
    fetchSubmodules = true;
  };
  installPhase = ''
    mkdir -p $out/bin
    cp $src/{kefctl,kefdsp,tools/detect-speakers.pl} $out/bin
  '';
}
