self: super:
with super.lib;
with super.builtins; let
  currentDirFiles = attrNames (readDir ./.);
  isNixFile = name: name != "default.nix" && (hasSuffix ".nix" name || pathExists (./. + "/${name}/default.nix"));
  nixFiles = filter isNixFile currentDirFiles;
  imports = map (name: import (./. + "/${name}")) nixFiles;
in {
  andrei = foldl' (flip extends) (_: super) imports self;
}
