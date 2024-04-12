{ lib ? (import <nixpkgs> {}).lib
, python3Packages ? (import <nixpkgs> {}).python3Packages
, fetchFromGitHub ? (import <nixpkgs> {}).fetchFromGitHub
}:

python3Packages.buildPythonPackage rec {
  pname = "we-get";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "rachmadaniHaryono";
    repo = "we-get";
    rev = "f74a5f5fcc176377204376992ed238442a49e55f";
    hash = "sha256-Q1IFYFiRo+0OU4u52AqG13cdAPMq3eOGPVkZ2mzh0Aw=";
  };

  format = "pyproject";

  nativeBuildInputs = with python3Packages; [
    poetry-core
  ];

  propagatedBuildInputs = with python3Packages; [
    colorama
    docopt
    requests
    beautifulsoup4
    prompt_toolkit
    pygments
  ];
}
