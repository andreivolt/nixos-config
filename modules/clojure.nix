{pkgs, ...}: {
  home-manager.users.andrei.home.packages = with pkgs; let
    edn = callPackage ../pkgs/edn {};
  in [
    babashka
    boot
    clojure
    clojure-lsp
    edn
    zprint
  ];
}
