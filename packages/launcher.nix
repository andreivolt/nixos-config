self: super: with super; {

launcher = writeShellScriptBin "launcher" ''
  echo '
    browser
    clojure-scratchpad
    colorpicker
    emacs-clojure
    emacs-notmuch
    emacs-prog
    private-browser
    rebuild
    todos
    todos-lib
    whattimeisit' \
  | \
    ${self.fzf}/bin/fzf \
      --reverse \
      --inline-info --color info:16 \
  | \
    xargs -i sh -c 'exec &>/dev/null setsid {}' '';

}
