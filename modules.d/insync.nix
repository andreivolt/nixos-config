{ lib, pkgs, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [ insync ];

  systemd.user.services.insync = {
    after = [ "network.target" ]; wantedBy = [ "default.target" ];
    path = [ pkgs.insync ];
    script = "insync start";
    serviceConfig.Type = "forking";
    serviceConfig.Restart = "always";
  };

  fileSystems =
    let
      dirs = [ "lib" "proj" "todo" "tmp" ];
      insync_root = "/home/avo/gdrive";
    in let _ = dir: {
      device = "${insync_root}/${dir}"; mountPoint = "/home/avo/${dir}";
      fsType = "none"; options = [ "bind" ];
    };
    in builtins.listToAttrs (map (dir: nameValuePair dir (_ dir)) dirs);
}
