{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gitAndTools.git-hub
  ];

  home-manager.users.avo
    .programs.git.extraConfig.hub = with (import ../credentials.nix).github; {
        username = user;
        oauthtoken = token;
      };
}
