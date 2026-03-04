inputs:
let
  inherit (builtins) readDir attrNames filter pathExists;
  entries = attrNames (readDir ./.);
  isOverlay = name:
    name != "default.nix"
    && (builtins.match ".*\\.nix" name != null
        || pathExists (./. + "/${name}/default.nix"));
in map (name: import (./. + "/${name}") inputs) (filter isOverlay entries)
