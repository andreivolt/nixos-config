{pkgs, lib, config, ...}:

let
  excludes = [
    "var/lib/docker/"
    "nix-build/"
  ];
  excludeFlags = lib.concatMapStrings (e: " --exclude ${lib.escapeShellArg e}") excludes;
in
{
  systemd.services.backup-persist = {
    description = "Backup /persist to Google Drive";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.rclone}/bin/rclone sync /persist gdrive:backup/persist-${config.networking.hostName} --config /home/andrei/.config/rclone/rclone.conf${excludeFlags} -v";
    };
  };

  systemd.timers.backup-persist = {
    description = "Daily backup of /persist to Google Drive";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };
}
