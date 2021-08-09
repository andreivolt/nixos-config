{ pkgs, config, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    home.file.".clojure/deps.edn".source = config.lib.file.mkOutOfStoreSymlink ./deps.edn;
  };
}
