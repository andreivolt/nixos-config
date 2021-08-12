{ pkgs, config, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    xdg.configFile."clojure/deps.edn".source = config.lib.file.mkOutOfStoreSymlink ./deps.edn;
  };
}
