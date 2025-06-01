{
  fetchFromGitHub,
  nodejs,
  stdenv,
}:
stdenv.mkDerivation {
  name = "nix-beautify";

  src = fetchFromGitHub {
    owner = "nixcloud";
    repo = "nix-beautify";
    rev = "d2f0317b182a26081582731cfcedf86ffeda5d4e";
    sha256 = "sha256-R87dA4CaErvvsLD4xzUDiwxZngMyef/4qmN8nW+tV54=";
  };

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/js
    cp $src/nix-beautify.js $out/js
    cat > $out/bin/nix-beautify << EOF
      #!/usr/bin/env bash
      ${nodejs}/bin/node $out/js/nix-beautify.js
    EOF
    chmod u+x $out/bin/nix-beautify
  '';
}
