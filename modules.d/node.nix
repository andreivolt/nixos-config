{ lib, ... }:

with lib;

{
  programs.npm.enable = true;
  programs.npm.npmrc = generators.toKeyValue {} {
    prefix = "~/.local/share/npm/packages";
    cache = "~/.cache/npm/packages";
  };

  environment.variables.PATH = mkAfter (concatStringsSep ":" [ "$PATH" "$HOME/.local/share/npm/packages/bin" ]);
}
