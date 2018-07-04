{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs.gitAndTools; [ hub ];

  home-manager.users.avo
    .programs.zsh.shellAliases.git =
      "${pkgs.gitAndTools.hub}/bin/hub";

  home-manager.users.avo
    .home.sessionVariables.GITHUB_TOKEN =
      (import ../private/credentials.nix).github.oauth_token;
}
