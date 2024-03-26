{ pkgs, config, ... }:

{
  home-manager.users.andrei = { pkgs, config, ... }: {
    home.packages = with pkgs; [
      clojure
      clojure-lsp
      leiningen
      zprint
    ];
  };
}
