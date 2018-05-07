{ config, lib, pkgs, ... }:

{
  imports = [
    ./ghci.nix
    ./brittany.nix
    ./stylish-haskell.nix
    ./stack.nix
  ];

  environment.systemPackages = with pkgs.haskellPackages; [
    apply-refact
    hindent
    hlint
  ];
}
