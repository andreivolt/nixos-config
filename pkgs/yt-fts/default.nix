{
  lib,
  python3,
  fetchFromGitHub,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "yt-fts";
  version = "38331d735496fec01c2b38c3612dc5171b837245";

  src = fetchFromGitHub {
    owner = "NotJoeMartinez";
    repo = "yt-fts";
    rev = version;
    sha256 = "sha256-1mZaxRPGQzYTrPnnM4Bmmq9eC3GvhkMJLJkRMO1KgyU=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    beautifulsoup4
    chromadb
    click
    openai
    pip
    requests
    rich
    sqlite-utils
  ];

  meta = with lib; {
    description = "A simple python script that uses yt-dlp to scrape all of a youtube channel's subtitles and load them into a searchable sqlite database";
    homepage = "https://github.com/NotJoeMartinez/yt-fts";
    license = licenses.mit;
  };
}
