# prefer nix-index's command-not-found
{ pkgs, config, ... }:

{
  home-manager.users.andrei.programs.command-not-found.enable = false;

  home-manager.users.andrei.programs.zsh.initExtra = ''
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
  '';
}
