{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ insync ];

  fileSystems =
    let
      dirs = [ "doc" "lib" "proj" "src" "tmp" ];
      template = dir: { device = "/home/avo/gdrive/" + dir;
                        fsType = "none"; options = [ "bind" ];
                        mountPoint = "/home/avo/" + dir; };

    in builtins.listToAttrs (map (name: lib.nameValuePair name (template name)) dirs);
}
