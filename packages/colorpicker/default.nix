{ pkgs ? import <nixpkgs> {} }:

pkgs.writeShellScriptBin "colorpicker" ''
  grim \
    -g "$(slurp -p)" \
    -t ppm - \
  | gm convert \
    - \
    -format '%[pixel:p{0,0}]' \
    txt:-
''
