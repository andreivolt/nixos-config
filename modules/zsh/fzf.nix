{ pkgs, ... }:

{
  # home-manager.users.andrei.programs.fzf.enableZshIntegration = true;
  home-manager.users.andrei.programs.zsh.initExtra = ''
    source ${pkgs.fzf}/share/fzf/completion.zsh
    source ${pkgs.fzf}/share/fzf/key-bindings.zsh
  '';
}
