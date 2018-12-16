(setq evil-want-keybinding nil)

;; (load "theme")

(setq sentence-end-double-space nil)

(setq-default tab-width 2
              indent-tabs-mode nil)

(setq-default scroll-bar-adjust-thumb-portion nil)

(setq vc-follow-symlinks t)

(setq-default cursor-in-non-selected-windows nil
              uniquify-buffer-name-style 'forward)

(setq truncate-partial-width-windows nil
      eldoc-idle-delay 0.2
      frame-title-format '("%b")
      inhibit-startup-screen t)

(setq-default mode-line-format '("%e " mode-line-modified " " mode-line-buffer-identification))

(require 'use-package)

(use-package srefactor
  :config
  (require 'srefactor-lisp))

(use-package parinfer
  :init
  (setq parinfer-extensions '(defaults
                               pretty-parens
                               ;; evil
                               smart-tab
                               smart-yank)))

(use-package writeroom-mode)

(use-package smartparens
  :init
  (use-package smartparens-config)
  :config
  (sp-with-modes sp--lisp-modes
    (sp-local-pair "'" nil :actions nil)
    (sp-local-pair "`" nil :actions nil))

  (smartparens-global-mode +1))

(use-package pretty-mode
  :config
  (global-pretty-mode t))

(use-package anzu
  :config
  (progn
    (defun my/anzu-update-func (here total)
      (when anzu--state
        (let ((status (cl-case anzu--state
                        (search (format " <%d/%d>" here total))
                        (replace-query (format " (%d Replaces)" total))
                        (replace (format " <%d/%d>" here total)))))
          (propertize status 'face 'anzu-mode-line))))
    (custom-set-variables '(anzu-mode-line-update-function #'my/anzu-update-func)))

  (global-anzu-mode +1))

(use-package link-hint :after evil
  :config
  (define-key evil-normal-state-map (kbd "SPC l") 'link-hint-open-link))

(use-package paren
  :config
  (show-paren-mode +1))

(progn
  (setq revert-without-query '(".*"))
  (setq auto-revert-verbose nil)
  (global-auto-revert-mode +1))

(fset #'yes-or-no-p #'y-or-n-p)

(use-package sort-words)

(use-package nav-flash
  :config
  (add-hook 'evil-jumps-post-jump-hook 'nav-flash-show)
  (dolist (fn '(evil-window-top evil-window-middle evil-window-bottom))
    (advice-add fn :after 'nav-flash-show)))

(use-package smex
  :config
  (smex-initialize)
  (global-set-key (kbd "M-x") 'smex))

(progn
  (use-package savehist
    :config
    (setq savehist-save-minibuffer-history t
          savehist-autosave-interval nil ; save on kill only
          savehist-additional-variables '(kill-ring search-ring regexp-search-ring))
    (savehist-mode +1))

  (use-package saveplace :after nav-flash
    :config
    (advice-add #'save-place-find-file-hook :after 'nav-flash-show)
    (advice-add #'save-place-find-file-hook :after-while '(lambda () (when buffer-file-name (ignore-errors (recenter)))))
    (save-place-mode +1)))

(use-package flyspell
  :init
  (setq ispell-program-name "hunspell"
        ispell-local-dictionary "en_US"
        ispell-local-dictionary-alist '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)
                                        ("fr_FR" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "fr-moderne") nil utf-8)
                                        ("ro_RO" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "ro_RO") nil utf-8)))
  :config
  (add-hook 'flyspell-mode-hook #'flyspell-buffer))

(progn
  (use-package company :after evil
    :init
    (setq company-transformers '(company-sort-by-occurrence))
    :config
    (global-company-mode +1))

  (use-package company-statistics
    :config
    (add-hook 'after-init-hook 'company-statistics-mode)))

(use-package ivy
  :config
  (setq ivy-height 20
        ivy-fixed-height-minibuffer t)
  (ivy-mode +1)
  (progn
    (define-key ivy-minibuffer-map (kbd "C-SPC") #'ivy-call-and-recenter)
    (define-key ivy-minibuffer-map (kbd "M-v") #'yank)
    (define-key ivy-minibuffer-map (kbd "M-z") #'undo)
    (define-key ivy-minibuffer-map (kbd "C-r") #'evil-paste-from-register)
    (define-key ivy-minibuffer-map (kbd "C-k") #'ivy-previous-line)
    (define-key ivy-minibuffer-map (kbd "C-j") #'ivy-next-line)
    (define-key ivy-minibuffer-map (kbd "C-l") #'ivy-alt-done)
    (define-key ivy-minibuffer-map (kbd "C-w") #'ivy-backward-kill-word)
    (define-key ivy-minibuffer-map (kbd "C-u") #'ivy-kill-line)
    (define-key ivy-minibuffer-map (kbd "C-b") #'backward-word)
    (define-key ivy-minibuffer-map (kbd "C-f") #'forward-word)))

(progn
  (progn
    (add-hook 'text-mode-hook (lambda () (variable-pitch-mode +1)))
    (add-hook 'text-mode-hook (lambda () (visual-line-mode +1))))

  (use-package typo
    :config
    (typo-global-mode 1)
    (add-hook 'text-mode-hook 'typo-mode)))

(setq evil-ex-search-vim-style-regexp t
      evil-ex-substitute-global t
      evil-respect-visual-line-mode t
      evil-symbol-word-search t
      evil-toggle-key ""
      evil-want-C-u-scroll t
      evil-want-Y-yank-to-eol t)

(use-package evil
  :config
  (setq evil-ex-search-vim-style-regexp t
        evil-ex-substitute-global t
        evil-want-keybinding nil
        evil-respect-visual-line-mode t
        evil-symbol-word-search t
        evil-toggle-key ""
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t)
  :init
  (setq evil-ex-search-vim-style-regexp t
        evil-ex-substitute-global t
        evil-respect-visual-line-mode t
        evil-symbol-word-search t
        evil-want-keybinding nil
        evil-toggle-key ""
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t)
  (use-package evil-expat :after evil)

  (use-package evil-visualstar
    :config
    (global-evil-visualstar-mode 1))

  (use-package evil-collection :after evil
    :config
    (evil-collection-init))

  (use-package evil-commentary
    :config
    (evil-commentary-mode 1))

  (use-package evil-goggles
    :config
    (evil-goggles-use-diff-faces)
    (setq evil-goggles-enable-change t)
    (evil-goggles-mode 1))

  (use-package evil-indent-plus
    :config
    (evil-indent-plus-default-bindings))

  (use-package evil-leader
    :config
    (global-evil-leader-mode)
    (evil-leader/set-leader "<SPC>"))

  (use-package evil-matchit :after evil
    :config
    (global-evil-matchit-mode 1))

  (use-package evil-snipe
    :config
    (evil-snipe-override-mode 1))

  (use-package evil-surround
    :config
    (global-evil-surround-mode 1))
  :config
  (evil-mode +1)

  (evil-define-key nil evil-normal-state-map
    "\C-h"'evil-window-left
    "\C-j" 'evil-window-down
    "\C-k" 'evil-window-up
    "\C-l" 'evil-window-right)

  (global-set-key (kbd "C-x C-g") 'evil-show-file-info)

  (with-eval-after-load "company"
    (cl-loop for (key . value)
             in '(("TAB" . company-select-next)
                  ("<backtab>" . company-select-previous)
                  ("RET" . nil))
             do (define-key company-active-map (kbd key) value)))

  (progn
    (use-package evil-numbers)
    (define-key evil-normal-state-map (kbd "C-c C-a") 'evil-numbers/inc-at-pt)
    (define-key evil-normal-state-map (kbd "C-c C-x") 'evil-numbers/dec-at-pt))

  (progn
    (define-key evil-visual-state-map (kbd "v") 'er/expand-region)
    (define-key evil-visual-state-map (kbd "V") 'er/contract-region))

  (progn
    (setq ivy-ignore-buffers '("\\` " "\\`\\*"))
    (define-key evil-normal-state-map (kbd "SPC b") 'ivy-switch-buffer))

  (define-key evil-normal-state-map (kbd "gp")
    '(lambda ()
       (cl-destructuring-bind (_ _ _ beg end &optional _) evil-last-paste
         (evil-visual-make-selection (save-excursion (goto-char beg) (point-marker)) end))))

  (progn
    (define-key evil-visual-state-map "J" (concat ":m '>+1" (kbd "RET") "gv=gv"))
    (define-key evil-visual-state-map "K" (concat ":m '<-2" (kbd "RET") "gv=gv")))

  (progn
    (define-key evil-visual-state-map (kbd "<")
      '(lambda ()
         (interactive)
         (evil-shift-left (region-beginning) (region-end))
         (evil-normal-state) (evil-visual-restore)))

    (define-key evil-visual-state-map (kbd ">")
      '(lambda ()
         (interactive)
         (evil-shift-right (region-beginning) (region-end))
         (evil-normal-state) (evil-visual-restore))))

  (evil-ex-define-cmd "retab"
                      '(lambda (&optional beg end)
                         (interactive "r")
                         (unless (and beg end) (setq beg (point-min) end (point-max)))
                         (if indent-tabs-mode (tabify beg end) (untabify beg end))))

  (evil-ex-define-cmd "cd"
                      '(lambda (path)
                         (interactive "D")
                         (cd path))))

(use-package hl-todo
  :config
  (global-hl-todo-mode +1))

(use-package dired
  :after evil
  :config
  (setq dired-no-confirm t
        dired-listing-switches "ls -lha --no-group --group-directories-first --classify --dereference-command-line -v"
        dired-recursive-copies 'always
        dired-recursive-deletes 'top)

  (setq global-auto-revert-non-file-buffers t)

  (progn
    (set-face-attribute 'dired-header nil :inherit 'default)
    (set-face-attribute 'dired-symlink nil :inherit 'default)
    (set-face-attribute 'dired-directory nil :inherit 'default
                        :weight 'bold))

  (defadvice dired-delete-entry (before force-clean-up-buffers (file) activate)
    (kill-buffer (get-file-buffer file)))

  (define-key dired-mode-map [remap quit-window]
    (lambda ()
      (interactive)
      (quit-window t)))

  (push (lambda ()
          (let ((parent-directory (file-name-directory buffer-file-name)))
            (when (not (file-exists-p parent-directory))
              (make-directory parent-directory t))))
   find-file-not-found-functions))

(use-package hl-todo
  :config
  (global-hl-todo-mode +1))

(use-package ripgrep)

(use-package neotree
  :init
  (setq neo-create-file-auto-open t
        neo-force-change-root t
        neo-mode-line-type 'none
        neo-show-updir-line nil
        neo-confirm-create-file #'off-p
        neo-confirm-create-directory #'off-p
        neo-window-width 30
        neo-show-hidden-files t
        neo-theme 'ascii
        neo-autorefresh t)
  :config
  (with-eval-after-load "evil"
    (with-eval-after-load "evil-leader"
      (evil-leader/set-key "e" 'neotree-toggle))

    (evil-define-key 'normal neotree-mode-map (kbd "<tab>") 'neotree-enter))

  ;; TODO
  ;; collapse all
  (evil-define-key 'normal neotree-mode-map (kbd "gc")
    (lambda ()
      (interactive)
      (setq list-of-expanded-folders neo-buffer--expanded-node-list)
      (dolist (folder list-of-expanded-folders)
        (neo-buffer--toggle-expand folder))))

  ;; cursor always on the first non-blank character
  (progn
    (defun +neotree*indent-cursor (&rest _)
      (beginning-of-line)
      (skip-chars-forward " \t\r"))

    (defun +neotree*fix-cursor (&rest _)
      (with-current-buffer neo-global--buffer (+neotree*indent-cursor)))

    (add-hook 'neo-enter-hook #'+neotree*fix-cursor)
    (advice-add 'neotree-next-line :after '+neotree*indent-cursor)
    (advice-add 'neotree-previous-line :after '+neotree*indent-cursor)))

(use-package nix-mode
  :mode ("\\.nix\\'"))

(use-package projectile
  :config
  (progn
    (setq projectile-require-project-root nil
          projectile-completion-system 'ivy)
    (projectile-mode +1))

  (evil-leader/set-key "f" 'projectile-find-file)

  (defun avo/minibuffer-kill-word ()
    "Kill a word, backwards, but only if the cursor is after `minibuffer-prompt-end', to prevent the 'Text is read-only' warning from monopolizing the minibuffer."
    (interactive)
    (when (> (point) (minibuffer-prompt-end))
      (call-interactively 'backward-kill-word)))

  (defun avo/minibuffer-kill-line ()
    "Kill the entire line, but only if the cursor is after `minibuffer-prompt-end', to prevent the 'Text is read-only' warning from monopolizing the minibuffer."
    (interactive)
    (when (> (point) (minibuffer-prompt-end))
      (call-interactively 'backward-kill-sentence)))

  (define-key minibuffer-local-map "C-w" 'avo/minibuffer-kill-word)
  ;; Restore common editing keys (and ESC) in minibuffer
  (dolist (map '(minibuffer-local-map
                 minibuffer-local-ns-map
                 minibuffer-local-completion-map
                 minibuffer-local-must-match-map
                 minibuffer-local-isearch-map
                 evil-ex-completion-map
                 evil-ex-search-keymap
                 read-expression-map))

    `(define-key ,map [escape] #'abort-recursive-edit)
    `(define-key ,map (kbd "C-r") 'evil-paste-from-register)
    `(define-key ,map (kbd "C-a") 'move-beginning-of-line)
    `(define-key ,map (kbd "C-w") 'avo/minibuffer-kill-word)
    `(define-key ,map (kbd "C-u") 'avo/minibuffer-kill-line)
    `(define-key ,map (kbd "C-b") 'backward-word)
    `(define-key ,map (kbd "C-f") 'forward-word)))

(use-package counsel
  :config
  (define-key ivy-mode-map [remap execute-extended-command] 'counsel-M-x))

(use-package magit
  :config
  (add-hook 'git-commit-mode-hook 'evil-insert-state)
  (use-package evil-magit))

(use-package git-gutter-fringe
  :config
  (setq-default fringes-outside-margins t)
  (fringe-mode '3)
  (progn
    (define-fringe-bitmap 'git-gutter-fr:added [224] nil nil '(center repeated))
    (define-fringe-bitmap 'git-gutter-fr:modified [224] nil nil '(center repeated))
    (define-fringe-bitmap 'git-gutter-fr:deleted [128 192 224 240] nil nil 'bottom)))

(use-package git-timemachine)

;; fix sexp macro indenting
(eval-after-load "lisp-mode"
  '(defun lisp-indent-function (indent-point state)
     "This function is the normal value of the variable `lisp-indent-function'.
The function `calculate-lisp-indent' calls this to determine
if the arguments of a Lisp function call should be indented specially.
INDENT-POINT is the position at which the line being indented begins.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position.
If the current line is in a call to a Lisp function that has a non-nil
property `lisp-indent-function' (or the deprecated `lisp-indent-hook'),
it specifies how to indent.  The property value can be:
* `defun', meaning indent `defun'-style
  \(this is also the case if there is no property and the function
  has a name that begins with \"def\", and three or more arguments);
* an integer N, meaning indent the first N arguments specially
  (like ordinary function arguments), and then indent any further
  arguments like a body;
* a function to call that returns the indentation (or nil).
  `lisp-indent-function' calls this function with the same two arguments
  that it itself received.
This function returns either the indentation to use, or nil if the
Lisp function does not specify a special indentation."
     (let ((normal-indent (current-column))
           (orig-point (point)))
       (goto-char (1+ (elt state 1)))
       (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
       (cond
        ;; car of form doesn't seem to be a symbol, or is a keyword
        ((and (elt state 2)
            (or (not (looking-at "\\sw\\|\\s_"))
               (looking-at ":")))
         (if (not (> (save-excursion (forward-line 1) (point))
                   calculate-lisp-indent-last-sexp))
             (progn (goto-char calculate-lisp-indent-last-sexp)
                    (beginning-of-line)
                    (parse-partial-sexp (point)
                                        calculate-lisp-indent-last-sexp 0 t)))
         ;; Indent under the list or under the first sexp on the same
         ;; line as calculate-lisp-indent-last-sexp.  Note that first
         ;; thing on that line has to be complete sexp since we are
         ;; inside the innermost containing sexp.
         (backward-prefix-chars)
         (current-column))
        ((and (save-excursion
               (goto-char indent-point)
               (skip-syntax-forward " ")
               (not (looking-at ":")))
            (save-excursion
              (goto-char orig-point)
              (looking-at ":")))
         (save-excursion
           (goto-char (+ 2 (elt state 1)))
           (current-column)))
        (t
         (let ((function (buffer-substring (point)
                                           (progn (forward-sexp 1) (point))))
               method)
           (setq method (or (function-get (intern-soft function)
                                         'lisp-indent-function)
                           (get (intern-soft function) 'lisp-indent-hook)))
           (cond ((or (eq method 'defun)
                     (and (null method)
                        (> (length function) 3)
                        (string-match "\\`def" function)))
                  (lisp-indent-defform state indent-point))
                 ((integerp method)
                  (lisp-indent-specform method state
                                        indent-point normal-indent))
                 (method
                  (funcall method indent-point state)))))))))

;; (use-package eval-sexp-fu :config
;;   (face-spec-set 'eval-sexp-fu-flash
;;                  `((t
;;                     :background ,light-blue :foreground ,background
;;                     :weight normal))))

(add-hook 'emacs-lisp-mode-hook 'parinfer-mode)


(progn
  (set-fringe-mode 0)

  (progn
    (tool-bar-mode -1)
    (menu-bar-mode -1))

  (set-window-scroll-bars (minibuffer-window) nil nil))
