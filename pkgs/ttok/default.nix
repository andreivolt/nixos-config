{
  lib,
  python3,
  fetchPypi,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "ttok";
  version = "0.2";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-tex7OTWBlLvSyuUPxYnl+ArDuxc645p+pNUj4sCi10U=";
  };
  propagatedBuildInputs = with python3.pkgs; [
    click
    tiktoken
  ];
  meta = with lib; {
    description = "Count and truncate text based on tokens";
    homepage = "https://github.com/simonw/ttok";
    license = licenses.asl20;
  };
}
