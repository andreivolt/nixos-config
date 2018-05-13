{ config, lib, pkgs, ... }:

{
  home-manager.users.avo
    .services.dropbox.enable = true;

  fileSystems =
    let
      dirs = [ "books" "doc" "media" "org" "proj" "tmp" ];
      template = dir: { device = "/home/avo/" + dir;
                        fsType = "none"; options = [ "bind" ];
                        mountPoint = "/home/avo/Dropbox/" + dir; };

    in builtins.listToAttrs (map (name: lib.nameValuePair name (template name)) dirs);
}
