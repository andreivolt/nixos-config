let
  pkgs = import <nixpkgs> {};
in
  pkgs.python3Packages.buildPythonPackage rec {
    pname = "aider";
    version = "0.12.0";

    src = pkgs.fetchFromGitHub {
      owner = "paul-gauthier";
      repo = "aider";
      rev = "v${version}";
      hash = "sha256-vPtiOsGZ5xkLjB8mZKQo0YVJbJuk55azImJtPVhHJO4=";
    };

    # BUG: not taking effect, use sed in postPatch instead
    # nativeBuildInputs = with pkgs.python3Packages; [ pythonRelaxDepsHook ];
    # pythonRelaxDeps = true;
    postPatch = ''
      # use sed to remove all version numbers from requirements.txt
      sed -i 's/==.*//g' requirements.txt
    '';

    # https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#handling-dependencies-handling-dependencies
    propagatedBuildInputs = with pkgs.python3Packages; [
      GitPython
      aiosignal
      async-timeout
      attrs
      backoff
      certifi
      charset-normalizer
      configargparse
      diskcache
      frozenlist
      gitdb
      idna
      jsonschema
      markdown-it-py
      mdurl
      multidict
      networkx
      numpy
      openai
      prompt-toolkit
      pygments
      pytest
      pythonRelaxDepsHook
      pyyaml
      requests
      rich
      scipy
      smmap
      sounddevice
      soundfile
      tiktoken
      tqdm
      urllib3
      wcwidth
      yarl
    ];

    doCheck = false; # tries to make network requests

    meta = with pkgs.lib; {
      description = "aider is GPT powered coding in your terminal";
      homepage = "https://github.com/paul-gauthier/aider";
      license = licenses.asl20;
      mainProgram = "aider";
      changelog = "https://github.com/paul-gauthier/aider/blob/main/HISTORY.md#${version}";
    };
  }
