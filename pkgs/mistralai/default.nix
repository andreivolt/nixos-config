{
  lib,
  python3,
  fetchFromGitHub,
  fetchPypi,
}: let
  mistralai = python3.pkgs.buildPythonPackage rec {
    pname = "mistralai";
    version = "0.0.12";
    format = "pyproject";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-/mUoNhRqFb3OdpGpWAOjLFPGQcVAAJNEf/qTvy7SlrI=";
    };
    nativeBuildInputs = with python3.pkgs; [
      poetry-core
    ];
    propagatedBuildInputs = with python3.pkgs; [
      httpx
      orjson
      pydantic
    ];
    pythonImportsCheck = ["mistralai"];
    meta = with lib; {
      description = "";
      homepage = "https://pypi.org/project/mistralai/";
      license = licenses.asl20;
      maintainers = with maintainers; [jpetrucciani];
    };
  };
in
  python3.pkgs.buildPythonApplication rec {
    pname = "gpt-command-line";
    version = "0.1.5";
    format = "pyproject";
    src = fetchFromGitHub {
      owner = "kharvd";
      repo = "gpt-cli";
      rev = "v${version}";
      sha256 = "sha256-nW0XbSmzlLAuZvGOh6kPdNq/JmPlP3gFrvZZH7yJQa0=";
    };
    propagatedBuildInputs = with python3.pkgs; [
      anthropic
      pip
      attrs
      black
      mistralai
      google-generativeai
      openai
      prompt-toolkit
      pytest
      pyyaml
      rich
      tiktoken
      tokenizers
      typing-extensions
    ];
    pythonImportsCheck = ["gptcli"];
    meta = with lib; {
      description = "Command-line interface for ChatGPT, Claude and Bard";
      homepage = "https://github.com/kharvd/gpt-cli";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  }
