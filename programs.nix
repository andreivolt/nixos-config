{ config, lib }:

(
  let path = ./programs; in
  (builtins.listToAttrs (map (n: lib.nameValuePair (lib.removeSuffix ".nix" n)
                                                   ({ enable = true; } // (import (path + ("/" + n)))))
                                 (lib.attrNames (builtins.readDir path))))
)
// (
  with config.home-manager.users.avo.programs; {
    home-manager.enable = true;
    nodejs.enable = true;
  })
