(progn
 (set-face-attribute 'window-divider nil :foreground color-background)
 (set-face-attribute 'variable-pitch nil :height 125)
 (modify-frame-parameters (selected-frame) '((internal-border-width . 15))))

(progn
  (setq org-todo-keywords
        '((sequence "TODO" "WAITING" "INFO" "DONE")))

  (setq org-todo-keyword-faces
        '(("TODO" . error)
          ("DONE" . success)
          ("WAITING" . warning)
          ("INFO" . default)))

  (add-hook 'org-mode-hook
            (lambda ()
              (push '("TODO" .  "☐") prettify-symbols-alist)
              (push '("WAITING" . "☐" ) prettify-symbols-alist)
              (push '("INFO" . "ⓘ" ) prettify-symbols-alist)
              (push '("DONE" . "☑" ) prettify-symbols-alist)
              (prettify-symbols-mode))))

(setq-default mode-line-format nil)

(use-package git-auto-commit-mode
  :config
  (git-auto-commit-mode))

;; sort headings on save
(add-hook 'before-save-hook
          (lambda ()
            (org-map-entries (lambda ()
                               (condition-case x
                                   (progn
                                     (org-sort-entries nil ?a)
                                     (org-sort-entries nil ?o))
                                 (user-error))))
            (outline-hide-sublevels 1)
            (beginning-of-buffer)))

(progn
 (defun format-phone-number (phone-number)
   (format "%010d" phone-number))

 (defun call (number)
   (call-process-shell-command (concat "phonecall " (format-phone-number number)) nil 0))

 (defun sms (number text)
   (call-process-shell-command (concat "sms " (format-phone-number number) " " text) nil 0)))

(use-package multicolumn
  :init
  (setq multicolumn-min-width 35)
  :config
  (add-hook 'before-save-hook 'multicolumn-delete-other-windows-and-split-with-follow-mode))

(progn
 (setq-default message-log-max nil)
 (kill-buffer "*Messages*"))

(defun todo-today ()
  (interactive)
  (org-schedule nil "."))
