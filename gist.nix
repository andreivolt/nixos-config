{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ gist ];

  home-manager.users.avo
    .home.file.".gist".text = (import ./credentials.nix).gist_token;
}
