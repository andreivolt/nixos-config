{ pkgs, config, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    home.packages = with pkgs; [
      clojure
      clojure-lsp
      zprint
    ];
    xdg.configFile."clojure/deps.edn".source = config.lib.file.mkOutOfStoreSymlink ./deps.edn;
  };
}
