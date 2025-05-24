{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  beautifulsoup4,
  pysocks,
  requests,
  retrying,
}:
buildPythonPackage rec {
  pname = "scihub";
  version = "1.0";
  src = fetchFromGitHub {
    owner = "andreivolt";
    repo = "scihub.py";
    rev = "4f108f6d1e3f44e3480a231f40632f73ddf96129";
    hash = "sha256-TEF1bOx7JINo0UB8rPsqB1k/yzUUqz8TZev1xhtbH8A=";
  };
  propagatedBuildInputs = [
    beautifulsoup4
    pysocks
    requests
    retrying
  ];
  meta = with lib; {
    description = "Python API and command-line tool for Sci-Hub";
    homepage = "https://github.com/zaytoun/scihub.py/";
    license = licenses.mit;
  };
}
