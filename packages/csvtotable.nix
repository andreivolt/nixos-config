{ pkgs ? (import <nixpkgs> {})
, stdenv ? pkgs.stdenv
}:

pkgs.python35Packages.buildPythonPackage {
  name = "csvtotable";
  src = pkgs.fetchFromGitHub {
    owner = "vividvilla";
    repo = "csvtotable";
    rev = "13aba68c42df9115dd14d11d75b17e6df9902b83";
    sha256 = "1clhja4spmmym8pgqlwbfbijk07xy9jlpfraswypfa088b5lib7n";
  };
  propagatedBuildInputs = [
    pkgs.python35Packages.jinja2
    pkgs.python35Packages.click
    pkgs.python35Packages.backports.csv
    #pkgs.python35Packages.buildPythonPackage {
    #  name = "backports.csv";
    #  src = pkgs.fetchurl {
    #    url = "https://pypi.python.org/pypi/backports.csv/1.0.5.tar.gz";
    #    sha256 = "0p23w44clj95i7idmjr7s5swfvsd8gs5hgna08iqa34v5mjvwvw1";
    #  };
    #};
  ];
};
