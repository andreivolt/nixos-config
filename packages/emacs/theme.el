(progn
  (set-fringe-mode 0)

  (progn
    (tool-bar-mode -1)
    (menu-bar-mode -1))

  (set-window-scroll-bars (minibuffer-window) nil nil))

(progn
  (defun add-side-padding-to-windows ()
    (set-window-margins nil 1 1))
  (add-hook 'window-configuration-change-hook 'add-side-padding-to-windows)
  (add-hook 'writeroom-mode-hook
            (lambda ()
              (remove-hook 'window-configuration-change-hook 'add-side-padding-to-windows))))

;; (progn
;;   (defun add-top-padding-to-windows ()
;;     (setq header-line-format " ")
;;     (set-face-attribute 'header-line nil
;;                         :background background
;;                         :height 0.5
;;                         :box nil))
;;   (add-hook 'window-configuration-change-hook 'add-top-padding-to-windows))

(progn
  (add-hook 'evil-insert-state-entry-hook (lambda () (blink-cursor-mode +1)))
  (add-hook 'evil-insert-state-exit-hook (lambda () (blink-cursor-mode -1))))

(progn
  (require 'color)
  (defun hsl-to-hex (&rest args)
    (apply 'color-rgb-to-hex (apply 'color-hsl-to-rgb args))))

(progn
  (defvar variable-pitch-font "Proxima Nova")
  (defvar fixed-pitch-font "Roboto Mono"))

(progn
  (progn
    (defvar background nil) (defvar background-light nil)
    (defvar foreground nil) (defvar foreground-light nil))

  (progn
    (defvar blue nil) (defvar light-blue nil)
    (defvar cyan nil) (defvar light-cyan nil)
    (defvar green nil) (defvar light-green nil)
    (defvar magenta nil) (defvar light-magenta nil)
    (defvar red nil) (defvar light-red nil)
    (defvar yellow nil) (defvar light-yellow nil)))

(defun avo/theme (&optional theme)
  (let ((theme (or theme 'light)))
    (if light
      (progn)
      (progn))))

(progn
  (defvar dark nil)
  (progn
    (if dark
        (progn
          (progn
            (setq foreground "#fffdf5") (setq foreground-light "#e6e3d3")
            (setq background (hsl-to-hex 0 0 .1)) (setq background-light "gray"))

          (progn
            (setq blue "#217dd9") (setq light-blue "#a6d2ff")
            (setq cyan "cyan") (setq light-cyan "lightcyan")
            (setq green "#24b353") (setq light-green "lightgreen")
            (setq magenta "magenta") (setq light-magenta "lightmagenta")
            (setq red "#24b353") (setq light-red "lightred")
            (setq yellow "#24b353") (setq light-yellow "lightyellow")))

      (progn
        (progn
          (setq background "#fffdf5") (setq background-light "#e6e3d3")
          (setq foreground (hsl-to-hex 0 0 .15)) (setq foreground-light (hsl-to-hex 0 0 .6)))

        (progn
          (setq blue "#217dd9") (setq light-blue "#a6d2ff")
          (setq cyan "cyan") (setq light-cyan "lightcyan")
          (setq green "#24b353") (setq light-green "lightgreen")
          (setq magenta "magenta") (setq light-magenta "lightmagenta")
          (setq red "#b33024") (setq light-red "lightred")
          (setq yellow "#d9b500") (setq light-yellow "lightyellow"))))

    (let ((font-height 110))
      (progn
        (set-face-attribute 'default nil
                            :font fixed-pitch-font
                            :height font-height
                            :foreground foreground :background background)

        (set-face-attribute 'variable-pitch nil
                            :font variable-pitch-font
                            :height 1.07))

      (progn
        (set-face-foreground 'error red)
        (set-face-foreground 'warning yellow)
        (set-face-foreground 'success green))

      ;; window dividers
      (add-hook 'prog-mode-hook
                (lambda ()
                  (set-face-attribute 'window-divider nil
                                      :foreground background-light)
                  (set-face-attribute 'fringe nil
                                      :background background)
                  (setq-default window-divider-default-places t
                                window-divider-default-bottom-width 2 window-divider-default-right-width 2)
                  (window-divider-mode)))

      (with-eval-after-load "nav-flash"
        (set-face-attribute 'nav-flash-face nil
                            :background light-blue))

      (with-eval-after-load "hl-todo"
        (setq hl-todo-keyword-faces `(("TODO" . ,green)
                                      ("FIXME" . ,red)
                                      ("NOTE" . ,foreground)))
        (set-face-bold 'hl-todo t))

      (with-eval-after-load "neotree"
        (add-hook 'neotree-mode-hook
                  (lambda ()
                    (face-remap-add-relative 'default
                                             `(:foreground ,foreground :background ,background-light))))

        (advice-add #'neo-global--select-window :after
                    '(lambda ()
                       (set-window-fringes neo-global--window 0 0)))

        (set-face-bold 'neo-dir-link-face t)

        (set-face-foreground 'neo-expand-btn-face background)

        (dolist (face '(neo-button-face
                        neo-dir-link-face
                        neo-expand-btn-face
                        neo-file-link-face
                        neo-header-face
                        neo-root-dir-face))
          (set-face-attribute face nil
                              :foreground foreground
                              :height 100))

        (set-face-attribute 'neo-root-dir-face nil
                            :weight 'bold
                            :foreground foreground)

        (when (display-graphic-p)
          (dolist (face '(neo-dir-link-face
                          neo-root-dir-face
                          neo-file-link-face))
            (set-face-attribute face nil :font variable-pitch-font))))

      (with-eval-after-load "git-gutter"
        (cl-loop for (key . value)
                 in '(("modified" . yellow)
                      ("deleted" . red)
                      ("added" . green))
                 do `(set-face-attribute (intern (concat "git-gutter:" key)) nil
                                         :foreground ,value :background ,value)))

      (set-face-attribute 'show-paren-match nil
                          :weight 'extrabold
                          :background (face-background 'default) :foreground blue)
      ;; ;; Company
      ;; (with-eval-after-load "company"
      ;;   (set-face-attribute 'company-scrollbar-bg nil
      ;;                       :background foreground)
      ;;   (set-face-attribute 'company-scrollbar-fg nil
      ;;                       :background (color 'bg))
      ;;   (set-face-attribute 'company-tooltip nil
      ;;                       :background foreground-darker :foreground (color 'bg -20))
      ;;   (set-face-attribute 'company-tooltip-common nil
      ;;                       :background foreground-darker :foreground (color 'bg -10))
      ;;   (set-face-attribute 'company-tooltip-common-selection nil
      ;;                       :background (color 'highlight) :foreground (color 'bg 20))
      ;;   (set-face-attribute 'company-tooltip-selection nil
      ;;                       :background (color 'highlight) :foreground (color 'fg 40)))

      (with-eval-after-load "evil-snipe"
        (set-face-attribute 'evil-snipe-matches-face nil
                            :background background :foreground blue
                            :underline t
                            :weight 'bold))

      (with-eval-after-load "anzu"
        (set-face-attribute 'anzu-mode-line nil
                            :font variable-pitch-font :weight 'bold
                            :foreground "white"))
      ;; cursor
      (with-eval-after-load "evil"
        (setq evil-normal-state-cursor `(,red (bar . 3)))
        (setq evil-visual-state-cursor `(,red (bar . 3)))
        (setq evil-insert-state-cursor `(,blue (bar . 3))))

      ;; mode line
      (progn
        (set-face-attribute 'mode-line nil
                            :font variable-pitch-font :weight 'normal
                            :background blue :foreground "white"
                            :box `(:line-width 3 :color ,blue))

        (set-face-attribute 'mode-line-inactive nil
                            :font variable-pitch-font :weight 'normal
                            :background background-light :foreground foreground
                            :box `(:line-width 3 :color ,background-light)))

      (with-eval-after-load "diff-mode"
        (cl-loop for (key . value)
                 in '(("added" . green) ("changed" . yellow) ("removed" . red))
                 do `(set-face-attribute (intern (concat "diff-" key)) nil
                                         :background ,value)))

      (progn
        (set-face-attribute 'highlight nil
                            :background yellow)

        (set-face-attribute 'lazy-highlight nil
                            :background background :foreground yellow
                            :weight 'bold :underline t)

        (set-face-attribute 'isearch nil
                            :background yellow :foreground foreground
                            :underline t)

        (set-face-attribute 'region nil
                            :background background-light))

      (progn
        (set-face-attribute 'font-lock-comment-face nil
                            :slant 'italic
                            :foreground blue)

        (set-face-attribute 'font-lock-string-face nil
                            :foreground foreground-light)

        (dolist (face '(builtin constant doc function-name keyword type variable-name))
          (set-face-attribute (intern (concat "font-lock-" (symbol-name face) "-face")) nil
                              :inherit 'default
                              :foreground foreground))))

    ;; minibuffer
    (progn (set-face-attribute 'minibuffer-prompt nil
                               :font variable-pitch-font :weight 'bold
                               :foreground blue)
           (add-hook 'minibuffer-setup-hook
                     (lambda ()
                       (set-window-scroll-bars (minibuffer-window) nil nil)
                       (set-window-fringes (minibuffer-window) 0 0 nil)
                       (set (make-local-variable 'face-remapping-alist)
                            `((default :foreground ,background :background ,foreground))))))

    (add-hook 'evil-command-window-mode-hook
              (lambda ()
                (face-remap-add-relative 'default
                                         `(:foreground ,background :background ,foreground))))))


