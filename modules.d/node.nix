{ lib, pkgs, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [ nodejs ];

  programs.npm = {
    enable = true;
    npmrc = generators.toKeyValue {} {
      prefix = "~/.local/share/npm/packages";
      cache = "~/.cache/npm/packages";
    };
  };

  environment.variables.PATH = mkAfter (concatStringsSep ":" [ "$PATH" "$HOME/.local/share/npm/packages/bin" ]);
}
