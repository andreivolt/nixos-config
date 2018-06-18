{ config, lib, pkgs, ... }:

{
  home-manager.users.avo
    .services.dropbox.enable = true;

  fileSystems =
    let
      dirs = [ "doc" "media" "proj" "tmp" "src" ];
      template = dir: { device = "/home/avo/" + dir;
                        fsType = "none"; options = [ "bind" ];
                        mountPoint = "/home/avo/Dropbox/" + dir; };

    in builtins.listToAttrs (map (name: lib.nameValuePair name (template name)) dirs);
}
