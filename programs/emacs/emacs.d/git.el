(progn
  (use-package magit :config
    (add-hook 'git-commit-mode-hook #'evil-insert-state))

  (use-package evil-magit :after magit)

  (use-package magit-blame :after git-timemachine))

;; git status in fringe
(if (display-graphic-p)
  (use-package git-gutter-fringe :config
    (setq-default fringes-outside-margins t)

    (progn
      (if (fboundp 'fringe-mode) (fringe-mode '3))
      (define-fringe-bitmap 'git-gutter-fr:added [224] nil nil '(center repeated))
      (define-fringe-bitmap 'git-gutter-fr:modified [224] nil nil '(center repeated))
      (define-fringe-bitmap 'git-gutter-fr:deleted [128 192 224 240] nil nil 'bottom)))

  (use-package git-gutter :init
    (setq git-gutter:update-interval 2)))

;; git-link
(use-package git-link :config
  ;open the website for the current version controlled file, fallback to repository root
  (evil-ex-define-cmd "gbrowse"
                      '(lambda ()
                        (interactive)
                        (require 'git-link)
                        (cl-destructuring-bind (beg end)
                            (if buffer-file-name (git-link--get-region))
                          (let ((git-link-open-in-browser t))
                            (git-link (git-link--select-remote) beg end))))))

;; git-timemachine
(use-package git-timemachine)
