{ pkgs, ... }:

{
  home-manager.users.avo.programs.zsh.initExtra = ''
    source ${pkgs.fzf}/share/fzf/completion.zsh
    source ${pkgs.fzf}/share/fzf/key-bindings.zsh
  '';
}
