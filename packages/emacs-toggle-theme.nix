self: super: with super; {

emacs-toggle-theme = writeShellScriptBin "emacs-toggle-theme" ''
  if [[ -n $1 ]]; then
    theme=$1
  else
    if [[ -f /tmp/.emacs-theme ]]; then
      if [[ $(< /tmp/.emacs-theme) = light ]]; then
        theme=dark
      else
        theme=light
      fi
    fi
  fi
  echo $theme > /tmp/.emacs-theme

  for daemon in \
    clojure \
    emacs-edit-server \
    main \
    notmuch \
  ; do
    ${self.avo.emacs}/bin/emacsclient \
      --socket $daemon \
      --eval "(avo/toggle-theme '$theme)"
  done'';

}
