{ lib, ... }:

with lib;

{
  fileSystems =
    let
      dirs = [ "lib" "proj" "todo" "tmp" ];
      insync_root = "/home/avo/gdrive";
    in let fs-attrs-for = dir: {
      device = "${insync_root}/${dir}"; mountPoint = "/home/avo/${dir}";
      fsType = "none"; options = [ "bind" ]; };
    in builtins.listToAttrs (map (dir: nameValuePair dir (fs-attrs-for dir)) dirs);
}
