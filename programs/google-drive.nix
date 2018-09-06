{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ insync ];

  services.xserver.displayManager.sessionCommands = lib.mkAfter ''
    ${pkgs.insync}/bin/insync start
  '';

  fileSystems =
    let
      dirs = [ "doc" "lib" "proj" "scans"  "todo"  "tmp" ];
      template = dir: {
        device = "/home/avo/gdrive/" + dir;
        fsType = "none"; options = [ "bind" ];
        mountPoint = "/home/avo/" + dir;
      };

    in builtins.listToAttrs (map (name: lib.nameValuePair name (template name)) dirs);
}
