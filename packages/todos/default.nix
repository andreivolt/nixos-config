self: super: with super; {

todos = let
  client = ''
    #!/usr/bin/env bash

    exec &>/dev/null setsid ${self.avo.emacs}/bin/emacsclient \
      --socket-name todos \
      --create-frame --frame-parameters='(quote (name . "todos"))' '';

  server = let _ = ''
    (load "${builtins.toString ./todos.el}")

    (progn
      (find-file "~/todo/todo.org")
      (setq initial-buffer-choice "~/todo/todo.org"))'';
  in ''
    #!/usr/bin/env bash

    exec ${self.avo.emacs}/bin/emacs \
      --fg-daemon=todos \
      --load ${writeText "_" _}'';
  in stdenv.mkDerivation {
    name = "todos";
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp ${writeScript "_" client} $out/bin/todos
      cp ${writeScript "_" server} $out/bin/todos_server''; };

}
