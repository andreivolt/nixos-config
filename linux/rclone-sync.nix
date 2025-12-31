{config, lib, pkgs, ...}:

{
  home-manager.users.andrei = {
    # Bidirectional sync of todo directory from Google Drive to ~/todo
    # Runs on a timer since rclone bisync doesn't support filesystem events
    systemd.user.services.rclone-bisync-todo = {
      Unit = {
        Description = "RClone bidirectional sync for todo";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone bisync gdrive:todo /home/andrei/todo \
            --create-empty-src-dirs \
            --compare size,modtime \
            --slow-hash-sync-only \
            --resilient \
            -v
        '';
      };
    };

    systemd.user.timers.rclone-bisync-todo = {
      Unit.Description = "Periodic bidirectional sync for todo";
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };

  # Ensure ~/todo directory exists with impermanence
  # (uncomment if using impermanence, otherwise create manually)
  # environment.persistence."/persist".users.andrei.directories = [ "todo" ];
}
