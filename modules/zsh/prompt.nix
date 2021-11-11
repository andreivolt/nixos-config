{
  home-manager.users.avo = { pkgs, ...}: {
    programs.zsh.initExtra = "source ${./prompt.zsh}";
  };
}
