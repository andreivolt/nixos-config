self: super: with self; {

emacs-irc = writeShellScriptBin "emacs-irc" ''
  exec &>/dev/null setsid \
    ${avo.emacs}/bin/emacs \
      --load ${builtins.toString ./irc.el}'';

}
