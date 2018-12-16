{ lib, pkgs, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [ direnv ];

  programs.zsh.interactiveShellInit = mkAfter ''
    eval "$(direnv hook zsh)"
  '';
}
