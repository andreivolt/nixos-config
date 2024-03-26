{ pkgs, ... }:

{
  launchd.user.agents.htu-file-watcher = {
    script = ''
      ${pkgs.fswatch}/bin/fswatch -o ~/Downloads | while read; do
        find ~/Downloads -type f -name 'htu_*' -exec mv {} ~/drive/htu_autobackup/ \;
      done
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
