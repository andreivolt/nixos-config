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
