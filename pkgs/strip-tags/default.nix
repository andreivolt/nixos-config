{
  buildPythonApplication,
  fetchFromGitHub,
  lib,
  pytestCheckHook,
  python3,
  pythonOlder,
  setuptools,
}:
buildPythonApplication rec {
  pname = "strip-tags";
  version = "0.5.1";
  pyproject = true;
  disabled = pythonOlder "3.8";
  src = fetchFromGitHub {
    owner = "simonw";
    repo = pname;
    rev = "refs/tags/${version}";
    hash = "sha256-Oy4xii668Y37gWJlXtF0LgU+r5seZX6l2SjlqLKzaSU=";
  };
  nativeBuildInputs = [
    setuptools
  ];
  propagatedBuildInputs = with python3.pkgs; [
    beautifulsoup4
    click
    html5lib
    setuptools # for pkg_resources
  ];
  nativeCheckInputs = with python3.pkgs; [
    cogapp
    pytestCheckHook
    pyyaml
    types-click
    types-pyyaml
    types-setuptools
  ];
  pytestFlagsArray = [
    "-svv"
    "tests/"
  ];
  pythonImportsCheck = [
    "strip_tags"
  ];
  meta = with lib; {
    homepage = "https://github.com/simonw/llm";
    description = "Access large language models from the command-line";
    changelog = "https://github.com/simonw/llm/releases/tag/${version}";
    license = licenses.asl20;
    mainProgram = pname;
  };
}
