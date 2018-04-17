self: pkgs: rec {

csvtotable = with pkgs; python35Packages.buildPythonPackage {
  name = "csvtotable";
  src = fetchFromGitHub {
    owner = "vividvilla";
    repo = "csvtotable";
    rev = "13aba68c42df9115dd14d11d75b17e6df9902b83";
    sha256 = "1clhja4spmmym8pgqlwbfbijk07xy9jlpfraswypfa088b5lib7n";
  };
  propagatedBuildInputs = [
    python35Packages.jinja2
    python35Packages.click
    python35Packages.backports.csv
    python35Packages.buildPythonPackage {
      name = "backports.csv";
      src = fetchurl {
        url = "https://pypi.python.org/pypi/backports.csv/1.0.5.tar.gz";
        sha256 = "0p23w44clj95i7idmjr7s5swfvsd8gs5hgna08iqa34v5mjvwvw1";
      };
    }
  ];
};

}
