{ beautifulsoup4
, buildPythonPackage
, colorama
, docopt
, fetchFromGitHub
, poetry-core
, prompt_toolkit
, pygments
}:

buildPythonPackage rec {
  pname = "we-get";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "rachmadaniHaryono";
    repo = "we-get";
    rev = "f74a5f5fcc176377204376992ed238442a49e55f";
    hash = "sha256-Q1IFYFiRo+0OU4u52AqG13cdAPMq3eOGPVkZ2mzh0Aw=";
  };

  format = "pyproject";

  nativeBuildInputs = [
    poetry-core
  ];

  propagatedBuildInputs = [
    colorama
    docopt
    beautifulsoup4
    prompt_toolkit
    pygments
  ];
}
