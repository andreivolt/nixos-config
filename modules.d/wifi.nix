{ lib, ... }:

with lib;

{
  networking.wireless = {
    enable = true;
    networks =
      mapAttrs'
        (k: v: nameValuePair k (listToAttrs [ (nameValuePair "psk" v) ]))
        (import /home/avo/lib/credentials.nix).wifi;
  };
}
