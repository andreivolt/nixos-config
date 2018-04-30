{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    boot
    clojure
    leiningen
    lighttable
    lumo
    # https:++github.com/uswitch/ej
  ];

  home-manager.users.avo.home.sessionVariables =
    with config.home-manager.users.avo.xdg; {
      BOOT_HOME = "${configHome}/boot"; BOOT_LOCAL_REPO = "${cacheHome}/boot";
    } // {
      BOOT_JVM_OPTIONS = ''
                         -client \
                         -XX:+TieredCompilation \
                         -XX:TieredStopAtLevel=1 \
                         -Xverify:none
                       '';
    };

  home-manager.users.avo.programs.zsh.shellAliases = {
    lumo = "lumo --cache ${config.home-manager.users.avo.xdg.cacheHome}/lumo";
  };

  home-manager.users.avo.xdg.configFile = {
    "boot/profile.boot".text = ''
      (deftask cider
        "CIDER profile"
        []
        (comp
          (do
           (require 'boot.repl)
           (swap! @(resolve 'boot.repl/*default-dependencies*)
                   concat '[[org.clojure/tools.nrepl "0.2.12"]
                            [cider/cider-nrepl "0.15.0"]
                            [refactor-nrepl "2.3.1"]])
           (swap! @(resolve 'boot.repl/*default-middleware*)
                   concat '[cider.nrepl/cider-middleware
                           refactor-nrepl.middleware/wrap-refactor])
           identity)))
    '';

    "clojure/deps.edn".text = ''
      ;; The deps.edn file describes the information needed to build a classpath.
      ;;
      ;; When using the `clojure` or `clj` script, there are several deps.edn files
      ;; that are combined:
      ;; - install-level
      ;; - user level (this file)
      ;; - project level (current directory when invoked)
      ;;
      ;; For all attributes other than :paths, these config files are merged left to right.
      ;; Only the last :paths is kept and others are dropped.

      {
        ;; Paths
        ;;   Directories in the current project to include in the classpath

        ;; :paths ["src"]

        ;; External dependencies

        ;; :deps {
        ;;   org.clojure/clojure {:mvn/version "1.9.0"}
        ;; }

        ;; Aliases
      	;;   resolve-deps aliases (-R) affect dependency resolution, options:
      	;;     :extra-deps - specifies extra deps to add to :deps
      	;;     :override-deps - specifies a coordinate to use instead of that in :deps
      	;;     :default-deps - specifies a coordinate to use for a lib if one isn't found
      	;;   make-classpath aliases (-C) affect the classpath generation, options:
      	;;     :extra-paths - vector of additional paths to add to the classpath
      	;;     :classpath-overrides - map of lib to path that overrides the result of resolving deps

        ;; :aliases {
        ;;   :deps {:extra-deps {org.clojure/tools.deps.alpha {:mvn/version "0.5.373"}}}
        ;;   :test {:extra-paths ["test"]}
        ;; }

        ;; Provider attributes

        ;; :mvn/repos {
        ;;   "central" {:url "https://repo1.maven.org/maven2/"}
        ;;   "clojars" {:url "https://clojars.org/repo"}
        ;; }
      }
    '';
  };
}
