#!/usr/bin/env bb

(require '[babashka.process :as p]
         '[cheshire.core :as json]
         '[clojure.string :as str]
         '[clojure.tools.cli :as cli])

(def opts
  {:livekit-url (or (System/getenv "LIVEKIT_URL") "ws://ampere:7880")
   :livekit-public-url (or (System/getenv "LIVEKIT_PUBLIC_URL") "wss://s.avolt.net")
   :livekit-key (or (System/getenv "LIVEKIT_API_KEY")
                    (try (str/trim (slurp "/run/secrets/livekit/api_key")) (catch Exception _ nil)))
   :livekit-secret (or (System/getenv "LIVEKIT_API_SECRET")
                       (try (str/trim (slurp "/run/secrets/livekit/api_secret")) (catch Exception _ nil)))})

(def modes
  {"region"  "Select a region"
   "window"  "Select a window"
   "monitor" "Select a monitor"
   "active"  "Active window"})

(def cli-options
  [["-a" "--audio" "Enable audio (system + mic)"]
   ["-s" "--scale FACTOR" "Scale video (e.g. 0.5 for half resolution)"
    :parse-fn #(Double/parseDouble %)]
   [nil "--no-copy" "Don't copy URL to clipboard"]
   ["-h" "--help"]])

(defn usage [summary]
  (str "Usage: screen-share [options] [MODE]\n"
       "\nModes:\n"
       (str/join "\n" (map (fn [[n d]] (format "  %-10s %s" n d)) (sort modes)))
       "\n\nOptions:\n" summary
       "\n\nEnvironment:\n"
       "  LIVEKIT_URL         LiveKit server for publishing (default: ws://ampere:7880)\n"
       "  LIVEKIT_PUBLIC_URL  Public URL for viewers (default: wss://s.avolt.net)\n"
       "  LIVEKIT_API_KEY     API key (default: /run/secrets/livekit/api_key)\n"
       "  LIVEKIT_API_SECRET  API secret (default: /run/secrets/livekit/api_secret)"))

(defn shell-quote [s]
  (str "'" (str/replace (str s) "'" "'\\''") "'"))

(defn stream-id []
  (let [bytes (byte-array 8)
        _ (.nextBytes (java.security.SecureRandom.) bytes)
        encoded (-> (java.util.Base64/getUrlEncoder)
                    (.encodeToString bytes)
                    str/lower-case
                    (str/replace #"[^a-z0-9]" ""))]
    (subs encoded 0 (min 8 (count encoded)))))

(defn setup-audio-mix []
  (let [null-mod (-> (p/shell {:out :string}
                       "pactl" "load-module" "module-null-sink"
                       "sink_name=screen_share_mix"
                       "sink_properties=device.description=ScreenShareMix")
                     :out str/trim)
        default-sink (-> (p/shell {:out :string} "pactl" "get-default-sink")
                         :out str/trim)
        sys-mod (-> (p/shell {:out :string}
                      "pactl" "load-module" "module-loopback"
                      (str "source=" default-sink ".monitor")
                      "sink=screen_share_mix"
                      "latency_msec=1")
                    :out str/trim)
        default-source (-> (p/shell {:out :string} "pactl" "get-default-source")
                           :out str/trim)
        mic-mod (-> (p/shell {:out :string}
                      "pactl" "load-module" "module-loopback"
                      (str "source=" default-source)
                      "sink=screen_share_mix"
                      "latency_msec=1")
                    :out str/trim)]
    {:modules [null-mod sys-mod mic-mod]
     :device "screen_share_mix.monitor"}))

(defn teardown-audio-mix [{:keys [modules]}]
  (doseq [m (reverse modules)]
    (p/shell {:continue true} "pactl" "unload-module" m)))

(defn geometry-region []
  (-> (p/shell {:out :string} "slurp" "-d") :out str/trim))

(defn geometry-monitor []
  (-> (p/shell {:out :string} "slurp" "-o") :out str/trim))

(defn geometry-window []
  (let [clients (-> (p/shell {:out :string} "hyprctl" "clients" "-j") :out)
        rects (->> (json/parse-string clients true)
                   (map (fn [{:keys [at size]}]
                          (format "%d,%d %dx%d" (first at) (second at) (first size) (second size))))
                   (str/join "\n"))]
    (-> (p/shell {:out :string :in rects} "slurp") :out str/trim)))

(defn geometry-active []
  (let [win (-> (p/shell {:out :string} "hyprctl" "activewindow" "-j") :out
                (json/parse-string true))
        [x y] (:at win)
        [w h] (:size win)]
    (format "%d,%d %dx%d" x y w h)))

(defn get-geometry [mode]
  (case mode
    "region"  (do (println "Select screen region...") (geometry-region))
    "window"  (do (println "Select window...") (geometry-window))
    "monitor" (do (println "Select monitor...") (geometry-monitor))
    "active"  (let [g (geometry-active)] (println "Active window:" g) g)))

(defn copy-to-clipboard [s]
  (p/shell {:in s} "wl-copy"))

(defn create-token [{:keys [livekit-key livekit-secret]} room identity & {:keys [can-publish] :or {can-publish false}}]
  (let [args (cond-> ["livekit-cli" "create-token"
                       "--api-key" livekit-key "--api-secret" livekit-secret
                       "--join" "--room" room "--identity" identity
                       "--valid-for" "24h"]
               (not can-publish) (into ["--grant" (json/generate-string {:canPublish false})]))
        result (apply p/shell {:out :string} args)
        output (str/trim (:out result))]
    (->> (str/split-lines output)
         (some #(when (str/starts-with? % "access token:") (str/trim (subs % 13)))))))

(defn upload-token [host path token]
  (p/shell {:in token} "ssh" host (str "cat > " path)))

(defn stream! [geometry sid {:keys [livekit-url livekit-public-url livekit-key livekit-secret] :as config} {:keys [audio no-copy scale]}]
  (let [audio-mix (when audio (setup-audio-mix))
        viewer-token (create-token config sid "viewer")
        _ (upload-token "ampere" (str "/var/lib/livekit-tokens/" sid) viewer-token)
        public-url (str/replace livekit-public-url #"^wss://" "https://")
        url (str public-url "/" sid "/")]
    (println (str "\nStream URL: " url "\n\nPress Ctrl+C to stop streaming\n"))
    (when-not no-copy (copy-to-clipboard url))
    (let [scale-filter (when scale
                        (format "scale=iw*%s:ih*%s" scale scale))
          rec-cmd (str/join " "
                   (cond-> ["wf-recorder" "-y"
                            "-g" (shell-quote geometry)
                            "-c" "libx264"
                            "-p" "preset=ultrafast"
                            "-p" "tune=zerolatency"
                            "-p" "profile=baseline"
                            "-p" "x264-params=keyint=15:repeat-headers=1:vbv-maxrate=8000:vbv-bufsize=4000"
                            "-r" "15"]
                     scale-filter (into ["-F" (shell-quote scale-filter)])
                     true  (into ["-m" "h264"
                                  "-f" "/dev/stdout"])
                     audio (into ["-a" "--audio-device" (shell-quote (:device audio-mix))])))
          lk-cmd (str "lk-publish"
                      " --url " (shell-quote livekit-url)
                      " --api-key " (shell-quote livekit-key)
                      " --api-secret " (shell-quote livekit-secret)
                      " --room " (shell-quote sid)
                      " --fps 15")
          cmd (str "trap 'kill 0 2>/dev/null' EXIT; "
                   rec-cmd " | " lk-cmd)]
      (try
        @(p/process {:err :inherit} "bash" "-c" cmd)
        (finally
          (when audio-mix (teardown-audio-mix audio-mix)))))))

(let [{:keys [options arguments summary errors]} (cli/parse-opts *command-line-args* cli-options)
      mode (or (first arguments) "region")]
  (when errors
    (doseq [e errors] (println e))
    (System/exit 1))
  (when (:help options)
    (println (usage summary))
    (System/exit 0))
  (when-not (contains? modes mode)
    (println "Unknown mode:" mode)
    (println (usage summary))
    (System/exit 1))
  (when-not (:livekit-key opts)
    (println "Error: LiveKit API key not found. Set LIVEKIT_API_KEY or ensure /run/secrets/livekit/api_key exists.")
    (System/exit 1))
  (when-not (:livekit-secret opts)
    (println "Error: LiveKit API secret not found. Set LIVEKIT_API_SECRET or ensure /run/secrets/livekit/api_secret exists.")
    (System/exit 1))
  (let [geometry (get-geometry mode)
        id (stream-id)]
    (stream! geometry id opts options)))
