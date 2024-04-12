{ pkgs, config, ... }:

{
  home-manager.users.andrei = { pkgs, config, ... }: {
    home.packages = with pkgs; let
      edn = callPackage ../pkgs/edn { };
    in [
      babashka
      boot
      clojure
      clojure-lsp
      edn
      leiningen
      zprint
    ];
  };
}
