{ pkgs, programs, ... }:

{
  environment.variables.PATH = [
    "$HOME/.local/share/npm/packages/bin"
  ];
  environment.systemPackages = [ pkgs.nodejs ];

  programs.npm.enable = true;
  programs.npm.npmrc = ''
    prefix = ~/.local/share/npm/packages
    cache = ~/.cache/npm/packages
  '';
}
