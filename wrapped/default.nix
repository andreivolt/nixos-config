self: super:

with super.lib;
with builtins;

{

wrapped =
  (foldl' (flip extends) (_: super)
    (map (n: import (./. + "/${n}"))
         (filter (n: match ".*\\.nix" n != null && n != "default.nix" || pathExists (./. + "/${n}/default.nix"))
                 (attrNames (readDir ./.)))))
    self;

}
