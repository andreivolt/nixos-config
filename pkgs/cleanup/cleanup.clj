#!/usr/bin/env bb

(require '[babashka.fs :as fs]
         '[babashka.process :as p]
         '[clojure.string :as str])

(def dry-run? (some #{"--dry-run" "-n"} *command-line-args*))

(defn sh [& args]
  (when-not dry-run?
    (apply p/shell {:out :inherit :err :inherit :continue true} args)))

(defn sh-out [& args]
  (-> (apply p/shell {:out :string :err :string :continue true} args) :out str/trim))

(defn avail-kb []
  (-> (p/shell {:out :string} "df" "--output=avail" "/")
      :out str/split-lines last str/trim parse-long))

(defn du [path]
  (when (fs/exists? path)
    (-> (sh-out "du" "-sh" (str path)) (str/split #"\t") first)))

(defn log [& args] (println "::" (str/join " " args)))

(defn rm-rf [path]
  (when (fs/exists? path)
    (if dry-run?
      (println "[dry-run] rm" (str path) (str "(" (du path) ")"))
      (fs/delete-tree path))))

(let [start-avail (avail-kb)]

  (log "cleaning direnv caches...")
  (doseq [d (fs/glob (fs/expand-home "~/dev") "**/.direnv" {:max-depth 3})]
    (rm-rf d))

  (log "nix garbage collection...")
  (if dry-run?
    (let [dead (-> (p/shell {:out :string} "nix-store" "--gc" "--print-dead")
                   :out str/split-lines count)]
      (println "[dry-run]" dead "paths"))
    (sh "nix-collect-garbage"))

  (log "cleaning ~/.cache...")
  (let [cache-dir (fs/expand-home "~/.cache")]
    (if dry-run?
      (println "[dry-run] rm" (str cache-dir) (str "(" (du cache-dir) ")"))
      (do (fs/delete-tree cache-dir)
          (fs/create-dir cache-dir))))

  (log "cleaning npm cache...")
  (when (fs/exists? (fs/expand-home "~/.npm"))
    (sh "npm" "cache" "clean" "--force"))

  (log "cleaning old Claude Desktop versions...")
  (let [versions-dir (fs/expand-home "~/.local/share/claude/versions")]
    (when (fs/exists? versions-dir)
      (let [versions (->> (fs/list-dir versions-dir)
                          (filter fs/directory?)
                          (sort-by fs/file-name)
                          reverse)]
        (doseq [old-ver (rest versions)]
          (rm-rf old-ver)))))

  (log "vacuuming journal...")
  (sh "sudo" "journalctl" "--vacuum-size=100M")

  (log "rust toolchains:")
  (let [tc-dir (fs/expand-home "~/.rustup/toolchains")]
    (when (fs/exists? tc-dir)
      (doseq [tc (fs/list-dir tc-dir)]
        (println " " (fs/file-name tc) (str "(" (du tc) ")")))))

  (log "cargo registry:" (du (fs/expand-home "~/.cargo/registry")))
  (log "/tmp:" (du "/tmp"))

  (let [end-avail (avail-kb)
        freed-mb (quot (- end-avail start-avail) 1024)]
    (log "freed" (str freed-mb "MB"))
    (println (sh-out "df" "-h" "/"))))
