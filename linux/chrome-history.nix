{pkgs, ...}:
let
  exportScript = pkgs.writers.writePython3 "chrome-history-export" {}
    (builtins.readFile ../shared/scripts/chrome-history-export.py);
in {
  home-manager.users.andrei = {
    systemd.user.services.chrome-history-export = {
      Unit.Description = "Export Chrome/Chromium history to Google Drive";
      Service = {
        Type = "oneshot";
        ExecStart = "${exportScript}";
      };
    };

    systemd.user.timers.chrome-history-export = {
      Unit.Description = "Periodically export Chrome history";
      Timer = {
        OnActiveSec = "0";     # Run immediately on first activation
        OnCalendar = "*:0/30"; # Then every 30 minutes
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
