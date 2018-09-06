{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ nodejs ];

  programs.npm = {
    enable = true;

    npmrc = lib.generators.toKeyValue {} {
      prefix = "~/.local/share/npm/packages";
      cache = "~/.cache/npm/packages";
    };
  };
}
