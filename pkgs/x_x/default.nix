{
  lib,
  python3,
  fetchPypi,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "x_x";
  version = "0.9";

  src = fetchPypi {
    inherit pname version;
    sha256 = "fC7vV8p/821nS+bdJj5emwg1nZz2EE+dd/DcYfTGNhs=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    click
    six
    xlrd
  ];
}
