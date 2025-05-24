{
  lib ? (import <nixpkgs> {}).lib,
  python3Packages ? (import <nixpkgs> {}).python3Packages,
  fetchPypi ? (import <nixpkgs> {}).fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "x_x";
  version = "0.9";

  src = fetchPypi {
    inherit pname version;
    sha256 = "fC7vV8p/821nS+bdJj5emwg1nZz2EE+dd/DcYfTGNhs=";
  };

  propagatedBuildInputs = with python3Packages; [
    click
    six
    xlrd
  ];
}
