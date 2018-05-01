{ pkgs, ... }:

{
  systemd.user.services.google-drive-ocamlfuse = {
    enable = true;
    wantedBy = [ "network-online.target" ];
    path = with pkgs; [ google-drive-ocamlfuse ];
    serviceConfig = with pkgs; {
      Type      = "forking";
      Restart   = "always";
      ExecStart = "${google-drive-ocamlfuse}/bin/google-drive-ocamlfuse gdrive";
      ExecStop  = "/run/current-system/sw/bin/fusermount -u gdrive";
    };
  };
}
