(load "common")

(setq-default mode-line-format nil)

(use-package markdown-mode
  :init
  (setq markdown-hide-markup t))

(use-package org
  :ensure org-plus-contrib
  :init
  ;; (setq org-src-block-faces `(("markdown" (:background ,background-light))))
  (setq org-confirm-elisp-link-function nil
        org-enforce-todo-dependencies t
        org-fontify-quote-and-verse-blocks t
        org-src-fontify-natively t
        org-fontify-whole-heading-line t
        org-hide-emphasis-markers t
        org-hide-leading-stars t
        org-src-tab-acts-natively t ; make auto indent work in code blocks
        org-startup-indented t)

  (progn
    (add-hook 'org-mode-hook
              (lambda ()
                (push '("TODO" .  "●") prettify-symbols-alist)
                (push '("NEXT" . "●" ) prettify-symbols-alist)
                (push '("DONE" . "●" ) prettify-symbols-alist)
                (push '("WAIT" . "●" ) prettify-symbols-alist)
                (push '("SOMEDAY" . "●" ) prettify-symbols-alist)
                (push '("IN-PROGRESS" . "●" ) prettify-symbols-alist)
                (prettify-symbols-mode)))

    (progn
      (progn
        (defface org-wait-face `((t (:foreground ,yellow))) "")
        (font-lock-add-keywords 'org-mode '(("WAIT.*" 0 'org-wait-face t))))
      (progn
        (defface org-in-progress-face `((t (:foreground ,blue))) "")
        (font-lock-add-keywords 'org-mode '(("IN-PROGRESS.*" 0 'org-in-progress-face t))))
      (progn
        (defface org-someday-face `((t (:foreground ,foreground-light))) "")
        (font-lock-add-keywords 'org-mode '(("SOMEDAY.*" 0 'org-someday-face t))))
      (progn
        (defface org-done-face `((t (:foreground ,green))) "")
        (font-lock-add-keywords 'org-mode '(("DONE.*" 0 'org-done-face t)))))

    (setq org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "IN-PROGRESS(i)" "WAIT(w)" "DONE(d)")
                              (sequence "TODO(t)" "SOMEDAY(s)" "|"))
          org-todo-keyword-faces '(("TODO" . org-todo-keyword-todo-face)
                                   ("NEXT" . org-todo-keyword-next-face)
                                   ("DONE" . org-todo-keyword-done-face)
                                   ("WAIT" . org-todo-keyword-wait-face)
                                   ("IN-PROGRESS" . org-todo-keyword-in-progress-face)
                                   ("SOMEDAY" . org-todo-keyword-someday-face)))

    (progn
      (defface org-todo-keyword `((t (:font ,fixed-pitch-font :weight extrabold))) "")
      (defface org-todo-keyword-todo-face `((t (:inherit org-todo-keyword :foreground ,background-light))) "")
      (defface org-todo-keyword-done-face `((t (:inherit org-todo-keyword :foreground ,green))) "")
      (defface org-todo-keyword-next-face `((t (:inherit org-todo-keyword :foreground ,red))) "")
      (defface org-todo-keyword-wait-face `((t (:inherit org-todo-keyword :foreground ,yellow))) "")
      (defface org-todo-keyword-in-progress-face `((t (:inherit org-todo-keyword :foreground ,blue))) "")
      (defface org-todo-keyword-someday-face `((t (:inherit org-todo-keyword :foreground ,background-light))) "")))

  :config
  (progn
    (defun org-wrap-source ()
      (interactive)
      (let ((start (min (point) (mark))) (end (max (point) (mark))))
        (goto-char end) (unless (bolp) (newline)) (insert "#+END_SRC\n")
        (goto-char start) (unless (bolp) (newline)) (insert "#+BEGIN_SRC\n")))
    (define-key evil-visual-state-map (kbd "gs") 'org-wrap-source))

  (progn
    (defun org-wrap-quote ()
      (interactive)
      (let ((start (min (point) (mark))) (end (max (point) (mark))))
        (goto-char end) (unless (bolp) (newline)) (insert "#+END_QUOTE\n")
        (goto-char start) (unless (bolp) (newline)) (insert "#+BEGIN_QUOTE\n")))
    (define-key evil-visual-state-map (kbd "gq") 'org-wrap-quote))

  (add-hook 'org-mode-hook 'visual-line-mode)

  (set-face-attribute 'org-checkbox-statistics-todo nil
                      :weight 'bold
                      :foreground foreground-light
                      :font fixed-pitch-font)

  (progn
    (flet ((format-phone-number (phone-number) (format "%010d" phone-number)))
      (defun call (number)
        (call-process-shell-command (concat "phonecall " (format-phone-number number)) nil 0))

      (defun sms (number text)
        (call-process-shell-command (concat "sms " (format-phone-number number) " " text) nil 0))))

  (progn
    (progn
      (setq org-ellipsis "  ●")
      (set-face-attribute 'org-ellipsis nil
                          :weight 'extrabold
                          :background nil :foreground blue
                          :underline nil))
    (let (value)
      (dotimes (number 8 value)
        (set-face-attribute (intern (concat "outline-" (number-to-string (+ 1 number)))) nil
                            :foreground foreground
                            :height 100
                            :weight 'normal :slant 'normal)))

    (set-face-attribute 'org-link nil
                        :foreground blue)

    (dolist (face '(org-code
                    org-formula
                    org-table))
      (face-spec-set face '((t :inherit 'fixed-pitch))))

    (set-face-attribute 'org-block nil
                        :background foreground-light :foreground background-light))

  (progn
    (defun org-summary-todo (n-done n-not-done)
      "Switch entry to DONE when all subentries are done, to TODO otherwise."
      (let (org-log-done org-log-states)
        (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
    (add-hook 'org-after-todo-statistics-hook 'org-summary-todo))

  (progn
    (progn
      (defun avo/next ()
        (interactive)
        (org-tags-view nil "+TODO=\"NEXT\""))
      (evil-leader/set-key "n" 'avo/next))

    (progn
      (defun avo/sort ()
        (interactive)
        (mark-whole-buffer)
        (org-sort-entries nil ?a)
        (org-sort-entries nil ?o)
        (outline-hide-sublevels 1)
        (deactivate-mark))
      (evil-leader/set-key "s" 'avo/sort))

    (progn
      (defun avo/done ()
        (interactive)
        (beginning-of-buffer)
        (delete-matching-lines "DONE"))
      (evil-leader/set-key "d" 'avo/done))))

(use-package evil-org
  :after org
  :config
  (add-hook 'org-mode-hook 'evil-org-mode)
  (add-hook 'evil-org-mode-hook
            (lambda ()
              (evil-org-set-key-theme '(additional
                                        heading
                                        insert
                                        navigation
                                        shift
                                        textobjects
                                        todo)))))

(use-package org-agenda
  :init
  (setq org-agenda-files '("~/todo")
        org-agenda-overriding-header ""
        org-agenda-prefix-format '((tags . "% b"))
        org-agenda-sorting-strategy '(alpha-up time-down)
        org-agenda-window-setup 'only-window)
  :config
  (add-hook 'org-agenda-mode-hook 'buffer-face-mode)

  (progn
    (evil-set-initial-state 'org-agenda-mode 'normal)))
    ;; (evil-define-key 'normal org-agenda-mode-map
    ;;   "j" 'org-agenda-next-line
    ;;   "k" 'org-agenda-previous-line
    ;;   "q" 'org-agenda-quit
    ;;   "t" 'org-agenda-todo
    ;;   (kbd "<RET>") 'org-agenda-switch-to
    ;;   (kbd "\t") 'org-agenda-goto)))

(use-package org-bullets
  :config
  (progn
    (defface org-bullet-face `((t (:foreground ,background))) "")
    (setq org-bullets-face-name 'org-bullet-face))
  (setq org-bullets-bullet-list '("·"))
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

(use-package org-web-tools)

(use-package markdown-mode)

(progn
  (set-face-attribute 'org-block nil :height 100)
  (set-face-attribute 'org-block-begin-line nil :foreground background-light :height 100)
  (set-face-attribute 'org-block-end-line nil :foreground background-light :height 100))

(add-hook 'org-after-todo-state-change-hook 'avo/sort)
