{ config, pkgs, ... }:

{
  imports =
    [
      ../profiles/graphical.nix
      ../profiles/workstation.nix
    ];
}
