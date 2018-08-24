self: pkgs: rec {

webapp = with pkgs; stdenv.mkDerivation rec {
  name = "webapp";

  src = [(pkgs.writeScript name ''
    #!/usr/bin/env bash

    name=$1
    url=$2

    ${pkgs.google-chrome-dev}/bin/google-chrome-unstable \
        --class=$name \
        --app="$url" \
        --no-first-run --no-default-browser-check \
        --user-data-dir=$XDG_CACHE_HOME/''${name}-webapp \
        &>/dev/null &

    disown
  '')];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
  '';
};

}
