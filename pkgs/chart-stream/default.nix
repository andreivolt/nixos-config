{
  fetchFromGitHub,
  mkYarnPackage,
}:
mkYarnPackage {
  name = "chart-stream";
  src = fetchFromGitHub {
    owner = "andreivolt";
    repo = "chart-stream";
    rev = "b9576722b78a023c4be83a7684d073c4177b5355";
    hash = "sha256-s7KwFsqZItJfxiMYcWxapPK697acDxSIxFphtDLngR0=";
  };
}
