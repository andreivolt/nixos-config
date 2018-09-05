{
  environment.variables.GREP_COLOR = "1";

  home-manager.users.avo
    .programs.zsh.shellAliases.grep = "grep --color=auto";
}
