(progn
  (use-package rainbow-blocks :config
    (add-hook 'prog-mode-hook 'rainbow-blocks-mode)

    (let (value)
      (dotimes (number 9 value)
        (set-face-attribute (intern (concat "rainbow-blocks-depth-" (number-to-string (+ 1 number)) "-face")) nil
                            :weight 'normal
                            :foreground (hsl-to-hex
                                         ;; (/ (* (/ 100 8) number) 100.0)
                                         (/ (* (/ 100 8) number) 85.0)
                                         1
                                         ;; (+ 0.15 (/ (* number 4) 100.0))
                                         (+ 0.15 (/ (* number 4) 100.0)))))))


  (use-package rainbow-delimiters :config
    (add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
    (let (value)
      (dotimes (number 9 value)
        (set-face-attribute (intern (concat "rainbow-delimiters-depth-" (number-to-string (+ 1 number)) "-face")) nil
                            :weight 'bold
                            :foreground (hsl-to-hex
                                         ;; (/ (* (/ 100 8) number) 100.0)
                                         (/ (* (/ 100 8) number) 85.0)
                                         1
                                         ;; (+ 0.15 (/ (* number 4) 100.0))
                                         (+ 0.15 (/ (* number 4) 100.0))))))))

(use-package srefactor
  :init
  (setq srecode-map-save-file (expand-file-name ".local/etc/srecode-map.el" user-emacs-directory))
  :config
  (require 'srefactor-lisp))
