{ config, pkgs, ... }:

let
  inputrc = pkgs.writeText "inputrc" ''
    set editing-mode vi

    set completion-ignore-case on
    set show-all-if-ambiguous  on

    set keymap vi
    C-r: reverse-search-history
    C-f: forward-search-history
    C-l: clear-screen
    v:   rlwrap-call-editor
  '';

in {
  environment.systemPackages = with pkgs; [ rlwrap ];

  environment.variables = {
    INPUTRC = "${inputrc}";
    RLWRAP_HOME = "~/.cache/rlwrap";
  };
}
