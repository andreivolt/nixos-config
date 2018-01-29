{ pkgs ? (import <nixpkgs> {})
, stdenv ? pkgs.stdenv
}:

stdenv.mkDerivation {
  name = "docker-compose-completions";

  src = pkgs.fetchFromGitHub {
    owner = "docker";
    repo = "compose";
    rev = "36772b555c976d81daca120ac15320fe13a605ee";
    sha256 = "11q24l7az17z1lwwymm6wacy61nbd44fxrqn5sygp2sm5k4p362i";
  };

  installPhase = ''
    mkdir -p $out/share/zsh/site-functions
    cp contrib/completion/zsh/_docker-compose $out/share/zsh/site-functions
  '';
}
