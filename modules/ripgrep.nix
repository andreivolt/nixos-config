{
  home-manager.users.andrei = { ... }: {
    programs.zsh.shellAliases.rg = "rg --smart-case --colors=match:fg:yellow";
  };
}
