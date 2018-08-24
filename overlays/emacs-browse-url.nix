self: pkgs: rec {

emacs-browse-url = with pkgs; stdenv.mkDerivation rec {
  name = "emacs-browse-url";

  src = [(pkgs.writeScript name ''
    #!/usr/bin/env bash
    
    url=$1
    
    ${pkgs.emacs}/bin/emacsclient \
        --socket-name scratchpad \
        --eval "(browse-url-emacs \"$url\")" \
        --no-wait
  '')];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
  '';
};

}
