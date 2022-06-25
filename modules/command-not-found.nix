# prefer nix-index's command-not-found
{ pkgs, config, ... }:

{
  home-manager.users.avo.programs.command-not-found.enable = false;

  home-manager.users.avo.programs.zsh.initExtra = ''
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
  '';
}
