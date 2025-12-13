#!/usr/bin/env bb

(ns content-bb
  (:require [clojure.core.match :refer [match]]
            [clojure.string :as str]
            [babashka.process :as p]))

(defn shell-escape [s]
  (str "'" (str/replace s "'" "'\"'\"'") "'"))

(defn process-url [input]
  (try
    (let [url (java.net.URL. input)]
      (if (re-matches #"^https?$" (.getProtocol url))
        (let [host (.getHost url)
              cmd (match [host]
                    [(:or "x.com" "twitter.com")] ["x-thread" "-p"]
                    [(:or "reddit.com" "old.reddit.com")] ["reddit-comments" input]
                    ["news.ycombinator.com"] ["hn-comments" input]
                    [h :guard #(or (.endsWith % "youtube.com") (= % "youtu.be"))] ["youtube-transcript" input]
                    :else ["sh" "-c" (str "firecrawl scrape '" input "' || puremd '" input "'")])]
          (:out (apply p/shell {:out :string} cmd)))
        (str "Invalid URL protocol: " input)))
    (catch Exception e
      (str "Not a URL: " input))))

(defn process-inputs [inputs]
  (let [results (pmap (fn [input]
                       {:input input :output (process-url input)})
                     inputs)]
    (if (= 1 (count inputs))
      (println (:output (first results)))
      (doseq [{:keys [input output error]} results]
        (println (str/join (repeat 80 "=")))
        (println input)
        (println (str/join (repeat 80 "=")))
        (println (or output error))
        (println)))))

(defn -main []
  (let [inputs (cond
                 (seq *command-line-args*) *command-line-args*
                 (zero? (:exit (p/shell {:out nil :continue true} "test" "-t" "0")))
                 (let [clipboard (str/trim (:out (p/shell {:out :string} "pbpaste")))]
                   (when (empty? clipboard)
                     (System/exit 1))
                   [clipboard])
                 :else
                 (-> (slurp *in*)
                     str/split-lines
                     (->> (map str/trim)
                          (remove empty?))))]
    (when (empty? inputs)
      (println "No input provided.")
      (System/exit 1))
    (process-inputs inputs)))

(-main)