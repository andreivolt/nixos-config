{ argcomplete
, beautifulsoup4
, buildPythonPackage
, chardet
, docx2txt
, extract-msg
, fetchFromGitHub
, fetchPypi
, lark
, lib
, pdfminer-six
, python-pptx
, rtfde
, six
, speechrecognition
, xlrd
}:

buildPythonPackage rec {
  pname = "textract";
  version = "1.5.0";
  name = "${pname}-${version}";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1mspqi2s2jcib8l11v6n2sqmnw9lgs5rx3nhbncby5zqg4bdswqf";
  };

  propagatedBuildInputs = [
    argcomplete
    beautifulsoup4
    chardet
    docx2txt
    (extract-msg.override {
      rtfde = (rtfde.overrideAttrs (oldAttrs: rec {
        doCheck = false;
      })).override {
        lark = lark.overrideAttrs (oldAttrs: rec {
          version = "1.1.8";
          src = fetchFromGitHub {
            owner = "lark-parser";
            repo = "lark";
            rev = "refs/tags/${version}";
            hash = "sha256-bGNoQeiAC2JIFOhgYUnc+nApa2ovFzXnpl9JQAE11hM=";
          };
        });
      };
    })
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
