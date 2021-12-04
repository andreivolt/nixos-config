{ pkgs, ... }:

{
  environment.variables
    .MANPAGER = "${pkgs.neovim}/bin/nvim +Man!";
}
