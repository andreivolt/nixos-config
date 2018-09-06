(use-package clojure-mode :config
  (subword-mode t)

  (dolist (mode '(eldoc-mode
                  ;; lispy-mode
                  parinfer-mode))
    (add-hook 'clojure-mode-hook mode))

  (defun clojure/fancify-symbols (mode)
    (font-lock-add-keywords mode `(("(\\(fn\\)[\[[:space:]]"      (0 (progn (compose-region (match-beginning 1) (match-end 1) "λ"))))
                                   ("(\\(partial\\)[\[[:space:]]" (0 (progn (compose-region (match-beginning 1) (match-end 1) "Ƥ"))))
                                   ("(\\(comp\\)[\[[:space:]]"    (0 (progn (compose-region (match-beginning 1) (match-end 1) "∘"))))
                                   ("\\(#\\)("                    (0 (progn (compose-region (match-beginning 1) (match-end 1) "ƒ"))))
                                   ("\\(#\\){"                    (0 (progn (compose-region (match-beginning 1) (match-end 1) "∈")))))))
  (clojure/fancify-symbols 'clojure-mode)

  (add-hook 'clojure-mode-hook (lambda ()
                                 (bind-key "<tab>" 'company-indent-or-complete-common clojure-mode-map)
                                 (bind-key "TAB" 'company-indent-or-complete-common clojure-mode-map))))

;; (add-hook 'clojure-mode-hook (lambda ()
;;                                (define-key lispy-mode-map-lispy "[" nil)
;;                                (define-key lispy-mode-map-lispy "]" nil)))


(use-package clj-refactor :after clojure-mode)

(use-package sayid)

(use-package cider
  :hook (clojure-mode . cider-mode)
  :config
  (setq cider-repl-display-help-banner nil))

(use-package cider-eval-sexp-fu)
