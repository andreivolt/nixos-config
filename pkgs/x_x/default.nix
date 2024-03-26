{ buildPythonPackage
, click
, fetchPypi
, six
, xlrd
}:

buildPythonPackage rec {
  pname = "x_x";
  version = "0.9";

  src = fetchPypi {
    inherit pname version;
    sha256 = "fC7vV8p/821nS+bdJj5emwg1nZz2EE+dd/DcYfTGNhs=";
  };

  propagatedBuildInputs = [
    click
    six
    xlrd
  ];
}
