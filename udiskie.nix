{ config, pkgs, ... }:

{
  systemd.user.services.udiskie = {
    enable = true;
    description = "Removable disk automounter";
    wantedBy = [ "default.target" ];
    path = with pkgs; [
      pythonPackages.udiskie
    ];
    serviceConfig = {
      Restart = "always";
      ExecStart = "${pkgs.pythonPackages.udiskie}/bin/udiskie --automount --notify --tray --use-udisks2";
    };
  };
}
