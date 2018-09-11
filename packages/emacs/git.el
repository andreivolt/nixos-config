(use-package magit
  :config
  (add-hook 'git-commit-mode-hook 'evil-insert-state))

(use-package evil-magit :after magit)

(use-package git-gutter-fringe
  :config
  (setq-default fringes-outside-margins t)
  (fringe-mode '3)
  (progn
    (define-fringe-bitmap 'git-gutter-fr:added [224] nil nil '(center repeated))
    (define-fringe-bitmap 'git-gutter-fr:modified [224] nil nil '(center repeated))
    (define-fringe-bitmap 'git-gutter-fr:deleted [128 192 224 240] nil nil 'bottom)))

(use-package git-timemachine)
