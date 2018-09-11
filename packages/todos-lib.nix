self: super: with super; {

todos-lib = let
  client = ''
    #!/usr/bin/env bash

    exec &>/dev/null setsid \
      ${self.avo.emacs}/bin/emacsclient \
        --socket-name todos-lib \
        --create-frame'';

  server = let _ = ''
    (load "${builtins.toString ./todos.el}")

    (progn
      (find-file "~/todo/lib.org")
      (setq initial-buffer-choice "~/todo/lib.org"))'';
  in ''
    #!/usr/bin/env bash

    exec \
      ${self.avo.emacs}/bin/emacs \
        --fg-daemon=todos-lib \
        --load ${writeText "_" _}'';
  in stdenv.mkDerivation {
    name = "todos";
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp ${writeScript "_" client} $out/bin/todos-lib
      cp ${writeScript "_" server} $out/bin/todos-lib_server''; };

}
