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
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/andrei/drive";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount gdrive: /home/andrei/drive \
            --vfs-cache-mode full \
            --vfs-cache-max-age 24h \
            --vfs-cache-max-size 2G \
            --vfs-fast-fingerprint \
            --vfs-read-chunk-size 32M \
            --vfs-read-chunk-size-limit off \
            --buffer-size 32M \
            --poll-interval 1m \
            --dir-cache-time 24h \
            --timeout 1h \
            --umask 002 \
            --allow-non-empty
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -u /home/andrei/drive";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}