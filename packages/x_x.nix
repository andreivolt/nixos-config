{ pkgs ? (import <nixpkgs> {})
, stdenv ? pkgs.stdenv
}:

pkgs.python35Packages.buildPythonPackage {
  name = "x_x";
  src = pkgs.fetchFromGitHub {
    owner = "kristianperkins";
    repo = "x_x";
    rev = "d236f8fcbccda04dd8d744c863ce312c0c966042";
    sha256 = "1h9bj19pa6p49rw9knzfn2v1pzgyk9aicmzzgxp5x96d38ry2zab";
  };
};
