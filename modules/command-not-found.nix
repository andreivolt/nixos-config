{ pkgs, config, ... }:

{
  programs.command-not-found.enable = false;

  home-manager.users.avo.programs.zsh.initExtra = ''
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
  '';
}
