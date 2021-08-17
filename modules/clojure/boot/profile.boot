(require 'boot.repl)

(swap! boot.repl/*default-dependencies*
       concat '[[cider/cider-nrepl "0.9.1"]])

(swap! boot.repl/*default-middleware*
       conj 'cider.nrepl/cider-middleware)

(in-ns boot.user
  (def mktemp java.io.File/createTempFile))
