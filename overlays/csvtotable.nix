self: pkgs: rec {

csvtotable = with pkgs; python27Packages.buildPythonPackage {
  name = "csvtotable";

  src = fetchFromGitHub {
    owner = "vividvilla";
    repo = "csvtotable";
    rev = "13aba68c42df9115dd14d11d75b17e6df9902b83";
    sha256 = "1clhja4spmmym8pgqlwbfbijk07xy9jlpfraswypfa088b5lib7n";
  };

  propagatedBuildInputs = with python27Packages; [
    backports_csv
    click
    jinja2
  ];
};

}
