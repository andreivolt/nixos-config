{ pkgs, config, ... }:

{
  home-manager.users.andrei = { pkgs, config, ... }: {
    home.packages = with pkgs; [
      clojure
      # clojure-lsp TODO
      leiningen
      # zprint
    ];
    xdg.configFile."clojure/deps.edn".source = config.lib.file.mkOutOfStoreSymlink ./deps.edn;
  };
}
