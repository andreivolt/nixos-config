{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; let
    todos = stdenv.mkDerivation rec {
      name = "todos";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        exec &>/dev/null

        ${pkgs.emacs}/bin/emacs \
          --name todos \
          --load ${./src/todos.el} \
          --eval '(multicolumn-delete-other-windows-and-split-with-follow-mode)' \
          ~/todo/todo.org &

        disown
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [ todos ];
}
