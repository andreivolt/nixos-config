(setq evil-want-integration nil)

(setq custom-file "~/.emacs.d/custom.el")

(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

(setq-default vc-follow-symlinks t)

(setq sentence-end-double-space nil)

(setq-default uniquify-buffer-name-style 'forward)

(setq-default cursor-in-non-selected-windows nil)

(setq eldoc-idle-delay 0.2)

(setq x-underline-at-descent-line t)

;; display continuation lines
(setq truncate-partial-width-windows nil)

;; tabs
(setq-default tab-width 2
              indent-tabs-mode nil)

(setq inhibit-startup-screen t)

;; set up packaging
(progn
  (progn
    (setq package-user-dir (expand-file-name ".local/packages/elpa" user-emacs-directory))
    (package-initialize)
    (setq package-archives '(("melpa" . "http://melpa.milkbox.net/packages/")
                             ("gnu" . "http://elpa.gnu.org/packages/")))
    ;; (package-refresh-contents)
    )
  (progn
    (setq quelpa-dir (expand-file-name ".local/packages/quelpa"
                                       user-emacs-directory))

    (require 'quelpa nil t)
  
    (setq quelpa-checkout-melpa-p nil)

    ;; (if (require 'quelpa nil t)
    ;;     (quelpa-self-upgrade)
    ;;   (with-temp-buffer
    ;;     (url-insert-file-contents "https://raw.github.com/quelpa/quelpa/master/bootstrap.el")
    ;;     (eval-buffer)))
    ;; (setq quelpa-stable-p t)
    (quelpa '(quelpa-use-package :fetcher github
                                 :repo "quelpa/quelpa-use-package"
                                 :stable nil))
    (require 'quelpa-use-package)
    (setq use-package-ensure-function 'quelpa))
  (setq use-package-always-ensure t))

;; auto-close delimiters
(use-package smartparens
  :config (require 'smartparens-config)(smartparens-global-mode +1))

;; window title
(setq frame-title-format '("%b"))

;; use Perl regexes
(use-package pcre2el
  :config (global-set-key [(meta %)]
                          'pcre-query-replace-regexp))

;; hide UI widgets
(dolist (f '(tool-bar-mode menu-bar-mode scroll-bar-mode))
  (when (fboundp f)
    (apply f
           '(-1))))

;; prettify symbols
(use-package pretty-mode
  :config (global-pretty-mode t))

;; variable pitch font in text mode
(add-hook 'text-mode-hook
          (lambda ()
            (variable-pitch-mode 1)))

;; show search position in mode line
(use-package anzu
  :config (defun my/anzu-update-func (here total)
            (when anzu--state
              (let ((status (cl-case anzu--state
                              (search (format " <%d/%d>" here total))
                              (replace-query (format " (%d Replaces)" total))
                              (replace (format " <%d/%d>" here total)))))
                (propertize status 'face 'anzu-mode-line))))(custom-set-variables '(anzu-mode-line-update-function #'my/anzu-update-func))(global-anzu-mode +1))

;; mode line
(setq-default mode-line-format '("%e " mode-line-modified " " mode-line-buffer-identification))

;; follow links using hints
(use-package link-hint
  :after evil
  :config (define-key evil-normal-state-map (kbd "SPC l") 'link-hint-open-link))

;; highlight matching delimiters
(use-package paren
  :config (show-paren-mode +1))

;; reload buffers when changed externally
(progn
  (setq revert-without-query '(".*"))
  (setq auto-revert-verbose nil)
  (global-auto-revert-mode +1))

;; y/n instead of yes/no
(fset #'yes-or-no-p #'y-or-n-p)

;; sort words
(use-package sort-words)

;; highlight jumps
(use-package nav-flash
  :config (add-hook 'evil-jumps-post-jump-hook 'nav-flash-show)(dolist (fn '(evil-window-top evil-window-middle evil-window-bottom))
                                                                 (advice-add fn :after 'nav-flash-show)))
;; put backups in temp dir
(setq backup-directory-alist `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

;; better M-x
(use-package smex
  :config (smex-initialize)(global-set-key (kbd "M-x")
                                           'smex))

;; persist state
(progn
  ;; ;; autosave session
  ;; (progn
  ;;   (require 'desktop)

  ;;   (setq desktop-save t
  ;;         desktop-load-locked-desktop t)

  ;;   (desktop-save-mode 1)

  ;;   (add-hook 'auto-save-hook (lambda () (desktop-save desktop-dirname))))

  ;; persist variables
  (use-package savehist
    :config (setq savehist-save-minibuffer-history t
                  savehist-autosave-interval
                  nil ; save on kill only
                  savehist-additional-variables
                  '(kill-ring search-ring regexp-search-ring))(savehist-mode +1))
  ;; persist point location
  (use-package saveplace
    :after nav-flash
    :config (advice-add #'save-place-find-file-hook :after 'nav-flash-show)(advice-add #'save-place-find-file-hook
                                                                                       :after-while '(lambda ()
                                                                                                       (when buffer-file-name
                                                                                                         (ignore-errors (recenter)))))(save-place-mode +1)))

;; spell checking
(use-package flyspell
  :config (add-hook 'flyspell-mode-hook #'flyspell-buffer))

;; theme
(load-file "~/.emacs.d/theme.el")

;; automatically clean up trailing whitespace on changed lines
;; (use-package ws-butler :config (ws-butler-global-mode))

;; completion
(progn
  (use-package company
    :after evil
    :init (setq company-transformers '(company-sort-by-occurrence)):config
    (global-company-mode +1))
  (use-package company-statistics
    :config (add-hook 'after-init-hook 'company-statistics-mode)))

;; menu completion
(use-package ivy
  :config (setq
           ;; ivy-re-builders-alist `((t . ivy--regex-fuzzy))
           ivy-initial-inputs-alist nil ivy-height 20
           projectile-completion-system 'ivy)(ivy-mode +1))

;; Evil
(progn
  (setq evil-toggle-key "")
  (use-package evil
    :init (setq evil-want-C-u-scroll t
                evil-ex-search-vim-style-regexp t
                evil-respect-visual-line-mode t
                evil-symbol-word-search t
                evil-ex-substitute-global t evil-want-Y-yank-to-eol t)
    :config
    (evil-mode +1)

    (evil-define-key nil evil-normal-state-map
      "\C-h" 'evil-window-left
      "\C-j" 'evil-window-down
      "\C-k" 'evil-window-up
      "\C-l" 'evil-window-right)

    (progn
      (global-set-key (kbd "C-x C-g")
                      'evil-show-file-info)
      (with-eval-after-load "company"
        (global-set-key (kbd "TAB")
                        'company-indent-or-complete-common)
        (cl-loop for
                 (key . value)
                 in
                 '(("TAB" . company-select-next)
                   ("<backtab>" . company-select-previous)
                   ("RET" . nil))
                 do
                 (define-key company-active-map (kbd key) value)))
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
      ;; reselect last pasted region
      (define-key evil-normal-state-map (kbd "gp") '(lambda ()
                                                      (cl-destructuring-bind (_ _ _ beg end &optional _)
                                                          evil-last-paste
                                                        (evil-visual-make-selection (save-excursion
                                                                                      (goto-char beg)
                                                                                      (point-marker))
                                                                                    end))))
      ;; move selected lines
      (progn
        (define-key evil-visual-state-map "J" (concat ":m '>+1"
                                                      (kbd "RET")
                                                      "gv=gv"))
        (define-key evil-visual-state-map "K" (concat ":m '<-2"
                                                      (kbd "RET")
                                                      "gv=gv"))))
    ;; keep visual selection visible while indenting
    (progn
      (define-key evil-visual-state-map (kbd "<") '(lambda ()
                                                     (interactive)
                                                     (evil-shift-left (region-beginning)
                                                                      (region-end))
                                                     (evil-normal-state)
                                                     (evil-visual-restore)))
      (define-key evil-visual-state-map (kbd ">") '(lambda ()
                                                     (interactive)
                                                     (evil-shift-right (region-beginning)
                                                                       (region-end))
                                                     (evil-normal-state)
                                                     (evil-visual-restore))))
    ;; retab
    (evil-ex-define-cmd "retab"
                        '(lambda (&optional beg end)
                           (interactive "r")
                           (unless (and beg end)
                             (setq beg (point-min)
                                   end
                                   (point-max)))
                           (if indent-tabs-mode
                               (tabify beg end)
                             (untabify beg end))))
    ;; cd
    (evil-ex-define-cmd "cd"
                        '(lambda (path)
                           (interactive "D")
                           (cd path))))
  (use-package evil-expat :after evil)
  ;; search with selected region
  (use-package evil-visualstar
    :config (global-evil-visualstar-mode 1))
  (use-package evil-collection
    :after evil
    :config (evil-collection-init))
  (use-package evil-commentary
    :config (evil-commentary-mode 1))
  (use-package evil-goggles
    :config (with-eval-after-load "diff-mode"
              (with-eval-after-load "evil-goggles"
                (evil-goggles-use-diff-faces)))(setq evil-goggles-enable-change t)(evil-goggles-mode 1))
  (use-package evil-indent-plus
    :config (evil-indent-plus-default-bindings))
  (use-package evil-leader
    :config (global-evil-leader-mode)(evil-leader/set-leader "<SPC>"))
  (use-package evil-matchit
    :after evil
    :config (global-evil-matchit-mode 1))
  (use-package evil-snipe
    :config (evil-snipe-override-mode 1))
  (use-package evil-surround
    :config (global-evil-surround-mode 1)))

;; file management
(progn
  (use-package dired
    :after evil
    :config (setq dired-no-confirm t dired-listing-switches
                  "-lha --indicator-style slash --no-group --group-directories-first"
                  dired-recursive-copies 'always dired-recursive-deletes
                  'top global-auto-revert-non-file-buffers t)(defadvice dired-delete-entry
                  (before force-clean-up-buffers
                          (file)
                          activate)
                  (kill-buffer (get-file-buffer file)))(define-key dired-mode-map [remap quit-window] (lambda ()
                                                                                                        (interactive)
                                                                                                        (quit-window t)))(push (lambda ()
                                                                                                        (let ((parent-directory (file-name-directory buffer-file-name)))
                                                                                                          (when (and (not (file-exists-p parent-directory))
                                                                                                                     (y-or-n-p (format "Directory `%s' does not exist! Create it?"
                                                                                                                                       parent-directory)))
                                                                                                            (make-directory parent-directory t))))
                  find-file-not-found-functions)))

;; minimal UI
(use-package writeroom-mode)

(load-file "~/.emacs.d/org-mode.el")

(set-fringe-mode 0)

;; (fringe-mode '(8 . 8))

;; (defun mode-line-fill (face reserve)
;; "Return empty space using FACE and leaving RESERVE space on the right."
;; (unless reserve
;; (setq reserve 20))
;; (when (and window-system (eq 'right (get-scroll-bar-mode)))
;; (setq reserve (- reserve 3)))
;; (propertize " "
;; 'display `((space :align-to (- (+ right right-fringe right-margin) ,reserve)))
;; 'face face))
;; (setq-default header-line-format (list
;; " "
;; 'mode-line-modified
;; " "
;; 'mode-line-buffer-identification
;; 'mode-line-modes
;; " -- "
;; `(vc-mode vc-mode)

;; ;; File modified
;; '(:eval (if (buffer-modified-p)
;; (list (mode-line-fill 'nil 12)
;; (propertize " [modified] " 'face 'header-line-red))
;; (list (mode-line-fill 'nil 9)
;; (propertize "%4l:%3c " 'face 'header-line))))
;; ))
;; (setq-default mode-line-format "")

;; (make-face 'header-line-grey)
;; (set-face-attribute 'header-line-grey nil
;; :weight 'medium
;; :foreground "#ffffff"
;; :background "#999999"
;; :box '(:line-width 1 :color "#999999"))
;; (make-face 'header-line-red)
;; (set-face-attribute 'header-line-red nil
;; :weight 'medium
;; :foreground "white"
;; :background "#dd7777"
;; :box '(:line-width 1 :color "#dd7777"))

;; (set-face-attribute 'mode-line nil
;; :height 10
;; :background "#999"
;; :box nil)
;; (set-face-attribute 'mode-line-inactive nil
;; :height 10
;; :background "#999"
;; :box nil)
;; (set-face-attribute 'header-line nil
;; :inherit nil
;; :foreground "white"
;; :background "#000000"
;; :box '(:line-width 3 :color "#000000"))

(defun acg-initial-buffer-choice ()
  (if (get-buffer "*scratch*")
      (kill-buffer "*scratch*"))
  (get-buffer "*Messages*"))

(setq initial-buffer-choice 'acg-initial-buffer-choice)
