{
  lib,
  python3,
  fetchFromGitHub,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "twscrape";
  version = "0.11.1";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "vladkens";
    repo = "twscrape";
    rev = "v${version}";
    sha256 = "sha256-ZnjLBS3r/LEWfBizLzvlyaxQeU7C7UhlnEXMKhjYjM4=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    aiosqlite
    fake-useragent
    httpx
    loguru
  ];

  nativeBuildInputs = with python3Packages; [
    hatchling
  ];

  meta = with lib; {
    description = "Twitter GraphQL and Search API implementation with SNScrape data models";
    homepage = "https://github.com/vladkens/twscrape";
    license = licenses.mit;
  };
}
