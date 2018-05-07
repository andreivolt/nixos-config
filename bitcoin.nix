{ config, lib, pkgs, ... }:


{
  environment.systemPackages = with pkgs; [ bitcoin ];

  home-manager.users.avo
    .xdg.configFile."bitcoin/bitcoin.conf".text = lib.generators.toKeyValue {} {
      prune = 550;
    };

  home-manager.users.avo
    .programs.zsh.shellAliases.bitcoin = with config.home-manager.users.avo;
      "${pkgs.bitcoin}/bin/bitcoin -datadir ${xdg.dataHome}/bitcoin/bitcoin.conf";
}
