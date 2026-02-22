{
  foot,
  fetchFromGitHub,
}:
foot.overrideAttrs (old: {
  pname = "foot-custom";
  src = fetchFromGitHub {
    owner = "andreivolt";
    repo = "foot";
    rev = "e75d6787924db65fcec326fddef7f529a501abae";
    hash = "sha256-Y80AQbnQ93HsGLb+eHtdkjM372emPbk5TKU7sPan+Ms=";
  };
})
