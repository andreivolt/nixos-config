(require 'notmuch)

(set-face-attribute 'default nil :height 120)

(use-package w3m)

(setq message-auto-save-directory "~/mail/Inbox.Drafts"
      message-directory "~/mail"
      mm-text-html-renderer 'w3m
      notmuch-fcc-dirs "Sent Items"
      notmuch-search-oldest-first nil
      notmuch-search-result-format `(("date" . "%12s  ")
                                     ("authors" . "%-20s  ")
                                     ("subject" . "%s  ")
                                     ("tags" . "(%s)"))
      send-mail-function 'sendmail-send-it
      sendmail-program "msmtp")

(dolist (hook '(notmuch-show-mode-hook
                notmuch-message-mode-hook))
  (add-hook hook
            (lambda ()
              (variable-pitch-mode +1)))

 (add-hook 'notmuch-show-hook
           (lambda()
             (notmuch-show-mark-read)
             (with-current-buffer "*notmuch-saved-search-inbox*"
                (notmuch-refresh-this-buffer))))
 ;; (notmuch-refresh-all-buffers)))

 (defun avo/inbox ()
   (interactive)
   (notmuch-search "tag:inbox")))
