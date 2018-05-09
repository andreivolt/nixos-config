{ lib, pkgs, ... }:

{
  systemd.user.services.google-drive-ocamlfuse = {
    enable = true;
    wantedBy = [ "network-online.target" ];
    path = with pkgs; [ google-drive-ocamlfuse ];
    serviceConfig = with pkgs; {
      Type      = "forking";
      Restart   = "always";
      ExecStart = "${google-drive-ocamlfuse}/bin/google-drive-ocamlfuse gdrive";
      ExecStop  = "${fuse}/bin/fusermount -u gdrive";
    };
  };

  home-manager.users.avo
    .home.file = builtins.listToAttrs (map (name: lib.nameValuePair (".gdfuse/default/" + name)
                                                                    { text = builtins.readFile (./private/gdfuse + ("/" + name)); })
                                           (lib.attrNames (builtins.readDir ./private/gdfuse)));
}
