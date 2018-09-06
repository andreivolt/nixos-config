(use-package notmuch :config
  (setq send-mail-function 'sendmail-send-it
        mm-text-html-renderer 'w3m)

  (dolist (hook '(notmuch-show-mode-hook
                  notmuch-message-mode-hook))
    (add-hook hook 'variable-pitch-mode)))
