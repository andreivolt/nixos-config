{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ boot ];

  environment.variables =
    {
      BOOT_HOME = "$HOME/.config/boot";
      BOOT_LOCAL_REPO = "$HOME/.cache/boot";
    } // {
      BOOT_JVM_OPTIONS = ''
        -client \
        -XX:+TieredCompilation \
        -XX:TieredStopAtLevel=1 \
        -Xverify:none\
      '';
    };

  home-manager.users.avo
    .xdg.configFile."boot/profile.boot".text = ''
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

  programs.zsh.interactiveShellInit = lib.mkAfter "
    alias boot='rlwrap -a -m boot'";
}
