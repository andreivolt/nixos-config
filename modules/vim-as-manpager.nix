{ pkgs, ... }:

{
  environment.variables
    .MANPAGER = "${pkgs.neovim}/bin/nvim -c 'set ft=man' -";
}
