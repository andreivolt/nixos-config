{
  lib ? (import <nixpkgs-unstable> {}).lib,
  python3Packages ? (import <nixpkgs-unstable> {}).python3Packages,
  fetchPypi ? (import <nixpkgs-unstable> {}).fetchPypi,
  fetchFromGitHub ? (import <nixpkgs-unstable> {}).fetchFromGitHub,
}: let
  customLark = python3Packages.lark.overrideAttrs (oldAttrs: rec {
    version = "1.1.8";
    src = fetchFromGitHub {
      owner = "lark-parser";
      repo = "lark";
      rev = "refs/tags/${version}";
      hash = "sha256-bGNoQeiAC2JIFOhgYUnc+nApa2ovFzXnpl9JQAE11hM=";
    };
  });

  customRtfde = python3Packages.rtfde.override {
    lark = customLark;
  };
  customRtfde' = customRtfde.overrideAttrs (oldAttrs: rec {
    doCheck = false;
  });

  customExtractMsg = python3Packages.extract-msg.override {
    rtfde = customRtfde';
  };
in
  python3Packages.buildPythonPackage rec {
    pname = "textract";
    version = "1.5.0";
    name = "${pname}-${version}";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1mspqi2s2jcib8l11v6n2sqmnw9lgs5rx3nhbncby5zqg4bdswqf";
    };

    propagatedBuildInputs = with python3Packages; [
      argcomplete
      beautifulsoup4
      chardet
      docx2txt
      customExtractMsg
      pdfminer-six
      python-pptx
      six
      speechrecognition
      xlrd
    ];

    doCheck = false;

    meta = with lib; {
      description = "extract text from any document. no muss. no fuss.";
      homepage = "https://pypi.python.org/pypi/textract";
      license = licenses.mit;
    };
  }
