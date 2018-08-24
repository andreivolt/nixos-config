self: pkgs: rec {

disposable-browser = with pkgs; stdenv.mkDerivation rec {
  name = "disposable-browser";

  src = [(pkgs.writeScript name ''
    #!/usr/bin/env bash

    setsid \
      ${pkgs.google-chrome-dev}/bin/google-chrome-unstable \
        --user-data-dir=$(mktemp -d) \
        --no-first-run --no-default-browser-check \
      &>/dev/null
  '')];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
  '';
};

}
