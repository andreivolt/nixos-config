{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "xanh-mono";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "yellow-type-foundry";
    repo = "xanhmono";
    rev = "HEAD";
    sha256 = "sha256-XM4Ee8BjaNw+wGzHQuWD9rcPPEBmHu/sk7lRBZ/PHHc=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm644 fonts/otf/*.otf -t $out/share/fonts/opentype
    install -Dm644 fonts/ttf/*.ttf -t $out/share/fonts/truetype

    runHook postInstall
  '';

  meta = with lib; {
    description = "Xanh Mono - A monospace font for coding";
    homepage = "https://github.com/yellow-type-foundry/xanhmono";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
