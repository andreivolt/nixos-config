{
  home-manager.users.avo = { ... }: {
    programs.zsh.shellAliases.rg = "rg --smart-case --colors=match:fg:yellow";
  };
}
