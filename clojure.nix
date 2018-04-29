{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    boot
    clojure
    leiningen
    lighttable
    lumo
    # https:++github.com/uswitch/ej
  ];

  home-manager.users.avo.home.sessionVariables = {
    BOOT_JVM_OPTIONS = ''
                         -client \
                         -XX:+TieredCompilation \
                         -XX:TieredStopAtLevel=1 \
                         -Xverify:none
                       '';
  };

  home-manager.users.avo.home.file = {
    ".boot/profile.boot".text = ''
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
  };
}
