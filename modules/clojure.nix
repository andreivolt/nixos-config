{pkgs, inputs, ...}: {
  home-manager.users.andrei.home.packages = with pkgs; let
    edn = callPackage "${inputs.self}/pkgs/edn" {};
  in [
    babashka
    boot
    clojure
    clojure-lsp
    edn
    zprint
  ];
}
