{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ ghi ];

  home-manager.users.avo
    .programs.git.extraConfig
      .ghi.token = (import ../private/credentials.nix).ghi_token;
}
