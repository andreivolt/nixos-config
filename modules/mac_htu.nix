{pkgs, ...}: {
  launchd.user.agents.htu-file-watcher = {
    script = ''
      ${pkgs.fswatch}/bin/fswatch -o ~/Downloads | while read; do
        find ~/Downloads -type f -name 'htu_*' | while read f; do
          cat $f >> ~/drive/htu.tsv
          rm $f
        done
      done
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
