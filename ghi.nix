{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ ghi ];

  home-manager.users.avo
    .programs.git.extraConfig
      .ghi.token = (import ./credentials.nix).ghi_token;
}
