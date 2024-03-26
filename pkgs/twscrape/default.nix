{ aiosqlite
, buildPythonPackage
, fake-useragent
, fetchFromGitHub
, hatchling
, httpx
, lib
, loguru
}:

buildPythonPackage rec {
  pname = "twscrape";
  version = "0.11.1";

  format = "pyproject";

  src = fetchFromGitHub {
    owner = "vladkens";
    repo = "twscrape";
    rev = "v${version}";
    sha256 = "sha256-ZnjLBS3r/LEWfBizLzvlyaxQeU7C7UhlnEXMKhjYjM4=";
  };

  propagatedBuildInputs = [
    aiosqlite
    fake-useragent
    httpx
    loguru
  ];

  nativeBuildInputs = [
    hatchling
  ];

  meta = with lib; {
    description = "Twitter GraphQL and Search API implementation with SNScrape data models";
    homepage = "https://github.com/vladkens/twscrape";
    license = licenses.mit;
  };
}
