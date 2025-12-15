self: super:
with super.lib;
with builtins; let
  currentDirFiles = attrNames (readDir ./.);
  isNixFile = name: name != "default.nix" && (hasSuffix ".nix" name || pathExists (./. + "/${name}/default.nix"));
  nixFiles = filter isNixFile currentDirFiles;

  # Create a lazy attribute set - packages are only evaluated when accessed
  # Use self.callPackage so packages can reference andrei.* siblings
  packages = listToAttrs (map (name: {
    name = name;  # Use directory name as-is
    value = self.callPackage (./. + "/${name}") {};
  }) nixFiles);
in {
  andrei = packages;
}
