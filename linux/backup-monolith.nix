{pkgs, ...}:

{
  home-manager.users.andrei = {
    systemd.user.services.backup-monolith = {
      Unit = {
        Description = "Backup monolith to Google Drive";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.rclone}/bin/rclone sync /home/andrei/.local/share/monolith gdrive:backup/monolith -v";
      };
    };

    systemd.user.timers.backup-monolith = {
      Unit.Description = "Daily backup of monolith to Google Drive";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
