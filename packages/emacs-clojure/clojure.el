(load "common")

(use-package subword-mode
  :hook clojure-mode)

(use-package evil
  :config
  (evil-global-set-key 'normal "p"
                       (lambda ()
                         (interactive)
                         (insert (shell-command-to-string "xclip -selection clipboard -o -t text/html | pandoc -f html -t org --wrap none | sed 's|\\\\||'")))))

(use-package clojure-mode
  :init
  (defun avo/scratchpad ()
    (let* ((temp-name (make-temp-name "scratchpad-"))
           (buffer-name (concat temp-name ".clj"))
           (buffer (generate-new-buffer buffer-name))
           (initial-code (string-join `(,(concat "(ns " temp-name ")")
                                        "(require 'boot.core)"
                                        "(boot.core/set-env! :dependencies '[[http-kit \"2.3.0\"]])")
                                      "\n\n")))
      (with-current-buffer buffer (clojure-mode))
      (switch-to-buffer buffer)
      (cider-jack-in-clj nil)
      (cider-jack-in-cljs :cljs-repl-type 'node)
      (with-current-buffer buffer
        (insert initial-code))))

  (setq clojure-align-forms-automatically t)

  :config
  (font-lock-add-keywords 'clojure-mode
                          (cl-map for (key . value)
                                  in '(("\\(fn\\)[\[[:space:]]" . "λ")
                                       ("\\(partial\\)[\[[:space:]]" . "Ƥ")
                                       ("(\\(comp\\)[\[[:space:]]" . "∘")
                                       ("\\(#\\)(" . "ƒ")
                                       ("\\(#\\){" . "∈"))
                                  do `(,key (0 (progn (compose-region (match-beginning 1) (match-end 1) ,value))))))

  (add-hook 'clojure-mode-hook
            (lambda ()
              (bind-key "<tab>" 'company-indent-or-complete-common clojure-mode-map)
              (bind-key "TAB" 'company-indent-or-complete-common clojure-mode-map))))

(use-package cider
  :init
  (setq cider-allow-jack-in-without-project t
        cider-jack-in-default "boot"
        cider-lein-parameters "repl :headless :host localhost"
        cider-repl-display-help-banner nil
        cider-repl-pop-to-buffer-on-connect nil
        cljr-suppress-no-project-warning t)
  :config
  (with-eval-after-load "clojure-mode"
    (with-eval-after-load "evil-leader"
      (evil-leader/set-key-for-mode 'clojure-mode
        "ce" 'cider-eval-defun-to-comment
        "cc" 'cider-pprint-eval-last-sexp-to-comment))))

(use-package cider-eval-sexp-fu :after cider)

(use-package clj-refactor
  :init
  (setq cljr-suppress-middleware-warnings t) ; supress errors outside project context
  :config
  (add-hook 'clojure-mode-hook
            (lambda ()
              (clj-refactor-mode 1)
              (yas-minor-mode 1))))
