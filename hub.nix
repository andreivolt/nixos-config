{ lib, pkgs, ... }:

{
  home-manager.users.avo
    .programs.zsh.shellAliases.git =
      "${pkgs.gitAndTools.hub}/bin/hub";

  home-manager.users.avo
    .xdg.configFile."hub".text =
      let credentials = import ./credentials.nix; in lib.generators.toYAML {} {
        "github.com" = [{
          user        = credentials.github.user;
          oauth_token = credentials.github.oauth_token;
        }];
      };
}
