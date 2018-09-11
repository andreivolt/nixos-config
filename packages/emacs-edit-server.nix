self: super: with super; {

emacs-edit-server = let _ = ''
  (use-package edit-server
    :config
    (edit-server-start))

  (use-package writeroom-mode
    :config
    (global-writeroom-mode 1))'';
in writeShellScriptBin "emacs-edit-server" ''
  exec \
    ${self.avo.emacs}/bin/emacs \
      --fg-daemon=edit-server \
      --load ${writeText "_" _}'';

}
