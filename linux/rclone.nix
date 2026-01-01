{ config, lib, pkgs, ... }:

{
  # Install rclone package
  environment.systemPackages = [ pkgs.rclone ];

  # RClone Google Drive mount service for user andrei
  home-manager.users.andrei = { config, pkgs, ... }: {
    systemd.user.services.rclone-gdrive = {
      Unit = {
        Description = "RClone Google Drive Mount";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "notify";
        # Clean up stale mount point before starting
        ExecStartPre = [
          "-${pkgs.fuse}/bin/fusermount -uz /home/andrei/drive"
          "${pkgs.coreutils}/bin/mkdir -p /home/andrei/drive"
        ];
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount gdrive: /home/andrei/drive \
            --vfs-cache-mode full \
            --vfs-cache-max-age 24h \
            --vfs-cache-max-size 2G \
            --vfs-fast-fingerprint \
            --vfs-read-chunk-size 64M \
            --vfs-read-chunk-size-limit off \
            --buffer-size 64M \
            --poll-interval 5m \
            --dir-cache-time 24h \
            --timeout 1h \
            --umask 002 \
            --allow-non-empty
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -uz /home/andrei/drive";
        # Cleanup even if process was killed
        ExecStopPost = "-${pkgs.fuse}/bin/fusermount -uz /home/andrei/drive";
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}