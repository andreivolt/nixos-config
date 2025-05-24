{
  fetchFromGitHub,
  mkYarnPackage,
}:
mkYarnPackage {
  name = "imagemin-cli";
  src = fetchFromGitHub {
    owner = "imagemin";
    repo = "imagemin-cli";
    rev = "2a87c5e4796d05dc1fa208f4f5c0f1722ec75dd4";
    hash = "sha256-3lS2hJLbVnG+GVbltgwBQkaKvUYf5wnx1qUNUewhfsA=";
  };
}
