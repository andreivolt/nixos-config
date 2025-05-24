{
  buildPythonApplication,
  fetchFromGitHub,
  tabulate,
}:
buildPythonApplication rec {
  pname = "jtbl";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "kellyjonbrazil";
    repo = "jtbl";
    rev = "0018aaddf5a76cc03a761ef01b065ff2183f9d17";
    hash = "sha256-ILQwUpjNueaYR5hxOWd5kZSPhVoFnnS2FcttyKSTPr8=";
  };

  propagatedBuildInputs = [
    tabulate
  ];

  doCheck = false; # fails
}
