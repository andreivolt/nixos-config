{pkgs, ...}:

{
  home-manager.users.andrei = {
    systemd.user.services.backup-claude-projects = {
      Unit = {
        Description = "Backup claude projects to Google Drive";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.rclone}/bin/rclone sync /home/andrei/.claude/projects gdrive:backup/claude-projects -v";
      };
    };

    systemd.user.timers.backup-claude-projects = {
      Unit.Description = "Daily backup of claude projects to Google Drive";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
