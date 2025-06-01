{
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation {
  name = "audd-cli";

  src = fetchFromGitHub {
    owner = "loiccoyle";
    repo = "audd-cli";
    rev = "40744f00c7f92f0ff525ce92012152915f375e0d";
    hash = "sha256-7AnXKabwGUwk8VEqF2lhbZzSz+PySnyxUHndIsCi3LE=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp audd audd-notif $out/bin
    chmod +x $out/bin/*
  '';
}
