self: super:

with self;
with super; {

emacs-notmuch = writeShellScriptBin "emacs-notmuch" ''
  exec &>/dev/null setsid \
    ${avo.emacs}/bin/emacsclient \
      --socket-name notmuch \
      --create-frame \
      --eval '(avo/inbox)' '';

emacs-notmuch-server = writeShellScriptBin "emacs-notmuch-server" ''
  exec ${avo.emacs}/bin/emacs \
    --fg-daemon=notmuch \
    --load ${builtins.toString ./notmuch.el}'';

}
