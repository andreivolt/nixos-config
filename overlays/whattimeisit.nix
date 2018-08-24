self: pkgs: rec {

whattimeisit = with pkgs; stdenv.mkDerivation rec {
  name = "whattimeisit";

  src = [(pkgs.writeScript name ''
    #!/usr/bin/env bash

    date +'%l:%M %p' | sed 's/^ //'
  '')];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
  '';
};

}
