{
  fetchFromGitHub,
  mkYarnPackage,
}:
mkYarnPackage {
  name = "livescript";
  src = fetchFromGitHub {
    owner = "gkz";
    repo = "LiveScript";
    rev = "6f754f9c51d133efa8a33504157db4c059ea23c1";
    hash = "sha256-uP9WvTpoeOFBs6b6hvcZgEFfbXhv2raJjS4aMiVqFJo=";
  };
}
