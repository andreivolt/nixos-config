self: super: {

emacs-clojure = let
  server = ''
    #!/usr/bin/env bash

    exec ${self.avo.emacs}/bin/emacs \
      --fg-daemon=clojure \
      --load ${builtins.toString ./clojure.el}'';

  client = ''
    #!/usr/bin/env bash

    exec &>/dev/null setsid ${self.avo.emacs}/bin/emacsclient \
      --socket-name clojure \
      --create-frame \
      "$@"'';

  scratchpad = ''
    #!/usr/bin/env bash

    exec &>/dev/null setsid ${self.avo.emacs}/bin/emacsclient \
      --socket-name clojure \
      --create-frame \
      --eval '(avo/scratchpad)' \
      "$@"'';
  in with super; stdenv.mkDerivation {
    name = "emacs-clojure";
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp ${writeScript "_" scratchpad} $out/bin/clojure-scratchpad
      cp ${writeScript "_" client} $out/bin/emacs-clojure
      cp ${writeScript "_" server} $out/bin/emacs-clojure_server''; };

}
