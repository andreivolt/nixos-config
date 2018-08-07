with import <nixpkgs> {};

let env = pkgs.haskellPackages.ghcWithPackages (p: with p; [xmonad xmonad-contrib]);
in

stdenv.mkDerivation rec {
  name = "avo-xmonad";

  src = ./src;

  buildInputs = [ xorg.xmessage ];

  installPhase = ''
    mkdir -p $out/bin
    ${env}/bin/ghc --make xmonad.hs -o $out/bin/xmonad
  '';
}
