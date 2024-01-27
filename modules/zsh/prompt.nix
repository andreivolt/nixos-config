{
  home-manager.users.andrei = { pkgs, ...}: {
    programs.zsh.initExtra = "source ${./prompt.zsh}";
  };
}
