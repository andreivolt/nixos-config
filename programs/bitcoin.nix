{ config, lib, pkgs, ... }:

let
  bitcoin-conf = pkgs.writeText "bitcoin.conf" (lib.generators.toKeyValue {} {
    prune = 550;
  });

in {
  environment.systemPackages = with pkgs; [ bitcoin ];

  programs.zsh.interactiveShellInit = lib.mkAfter "
    alias bitcoin='${pkgs.bitcoin}/bin/bitcoin \
      -conf ${bitcoin-conf} \
      -datadir ~/.local/share/bitcoin'";
}
