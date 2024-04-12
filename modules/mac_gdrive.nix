{ config, pkgs, ... }:

{
  launchd.user.agents.rclone-mount = {
    script = ''
      mkdir -p ~/gdrive
      exec ${pkgs.rclone}/bin/rclone mount gdrive: ~/gdrive \
        --vfs-cache-mode full \
        --no-modtime \
        --drive-acknowledge-abuse=true
    '';

    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
