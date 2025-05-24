{
  fetchFromGitHub,
  installShellFiles,
  lib,
  stdenv,
}:
stdenv.mkDerivation rec {
  name = "cuff-${version}";
  version = "1.0";

  nativeBuildInputs = [installShellFiles];

  src = fetchFromGitHub {
    owner = "loiccoyle";
    repo = "cuff";
    rev = "6c7b19520ff74dc2eecb096a64ec368714565467";
    hash = "sha256-mpBhQ4GultmYDCtt/J8Ky3nnFpVwPwuC3EiOaoQYTos=";
  };

  installPhase = ''
    installShellCompletion --zsh completions/zsh
    install -Dm555 cuff $out/bin/cuff
  '';

  meta = with lib; {
    platforms = platforms.linux;
  };
}
