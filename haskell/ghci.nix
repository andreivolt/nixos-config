{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs.haskellPackages; [ ghc ];

  home-manager.users.avo
    .xdg.configFile."ghc/ghci.conf".text = ''
      :set prompt "λ "
    '';

  home-manager.users.avo
    .programs.zsh.shellAliases.ghci = with config.home-manager.users.avo;
      "${pkgs.ghc}/bin/ghci --script ${xdg.configHome}/ghc/ghci.conf";
}
