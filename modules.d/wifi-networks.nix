{ lib, ... }:

with lib;

{
  networking.wireless.networks =
    mapAttrs'
      (k: v: nameValuePair k (listToAttrs [ (nameValuePair "psk" v) ]))
      (import /home/avo/lib/credentials.nix).wifi;
}
