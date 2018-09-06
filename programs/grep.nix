{ lib, ... }:

{
  environment.variables.GREP_COLOR = "1";

  programs.zsh.interactiveShellInit = lib.mkAfter "alias grep='grep --color=auto'";
}
