{ config, pkgs, ... }:

{
  imports = [
    ./boot.nix
    ./lumo.nix
  ];

  environment.systemPackages = with pkgs; [
    leiningen
    lighttable
    # https://github.com/uswitch/ej
  ];
}
