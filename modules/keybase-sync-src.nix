{
  systemd.services.keybase-sync-src  = {
    startAt = "*-*-* 05:20:00";
    path = [ pkgs.coreutils ];
    environment.HOME = "/home/avo";
    script = "${pkgs.rsync}/bin/rsync --delete --links --progress --verbose --recursive $HOME/src $HOME/keybase/private/andreivolt";
    serviceConfig.User = "avo";
  };
}
