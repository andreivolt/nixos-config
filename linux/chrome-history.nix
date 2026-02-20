{pkgs, ...}:
let
  exportScript = pkgs.writers.writePython3 "chrome-history-export" {} ''
    import os
    import shutil
    import sqlite3
    import subprocess
    import sys
    import tempfile
    from pathlib import Path

    WEBKIT_EPOCH_OFFSET = 11644473600
    RCLONE = "${pkgs.rclone}/bin/rclone"
    REMOTE = "gdrive:chrome-history.tsv"
    LOCAL_WORK = Path(tempfile.gettempdir()) / "chrome-history-work.tsv"


    def webkit_to_unix(webkit_time):
        return (webkit_time / 1_000_000) - WEBKIT_EPOCH_OFFSET


    def unix_to_webkit(unix_time):
        return int((unix_time + WEBKIT_EPOCH_OFFSET) * 1_000_000)


    def format_timestamp(unix_time):
        return f"U{int(unix_time * 1000)}.{int((unix_time % 1) * 1000):03d}"


    def parse_timestamp(ts_str):
        if ts_str.startswith("U"):
            ts_str = ts_str[1:]
        parts = ts_str.split(".")
        ms = int(parts[0])
        frac = int(parts[1]) if len(parts) > 1 else 0
        return ms / 1000 + frac / 1_000_000


    def find_history_db():
        candidates = [
            Path.home() / ".config" / "google-chrome" / "Default" / "History",
            Path.home() / ".config" / "chromium" / "Default" / "History",
        ]
        for path in candidates:
            if path.exists():
                return path
        return None


    def load_tsv(path):
        entries = {}
        if not path.exists():
            return entries
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                if not line:
                    continue
                parts = line.split("\t")
                if len(parts) >= 2:
                    url, ts_str = parts[0], parts[1]
                    unix_time = parse_timestamp(ts_str)
                    webkit_time = unix_to_webkit(unix_time)
                    entries[(url, webkit_time)] = line
        return entries


    def fetch_new_entries(db_path):
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as tmp:
            tmp_path = tmp.name
        try:
            shutil.copy2(db_path, tmp_path)
            conn = sqlite3.connect(tmp_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT visits.visit_time, urls.url, urls.visit_count, urls.title
                FROM urls
                INNER JOIN visits ON urls.id = visits.url
                ORDER BY visits.visit_time ASC
            """)
            for webkit_time, url, visit_count, title in cursor:
                unix_time = webkit_to_unix(webkit_time)
                ts_str = format_timestamp(unix_time)
                safe_title = (title or "").replace("\t", " ").replace("\n", " ")
                line = f"{url}\t{ts_str}\t{visit_count}\t{safe_title}"
                yield (url, webkit_time), line
            conn.close()
        finally:
            os.unlink(tmp_path)


    def main():
        db_path = find_history_db()
        if not db_path:
            print("No Chrome/Chromium history database found")
            return

        # Download latest from Drive directly (bypasses FUSE cache)
        subprocess.run(
            [RCLONE, "copyto", REMOTE, str(LOCAL_WORK)],
            capture_output=True,
        )

        entries = load_tsv(LOCAL_WORK)
        initial_count = len(entries)

        for key, line in fetch_new_entries(db_path):
            if key not in entries:
                entries[key] = line

        new_count = len(entries) - initial_count
        print(f"Found {new_count} new entries (total: {len(entries)})")

        if new_count == 0:
            return

        sorted_entries = sorted(entries.items(), key=lambda x: x[0][1])
        with open(LOCAL_WORK, "w", encoding="utf-8") as f:
            for _, line in sorted_entries:
                f.write(line + "\n")

        # Upload back to Drive directly
        result = subprocess.run(
            [RCLONE, "copyto", str(LOCAL_WORK), REMOTE],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"Upload failed: {result.stderr}")
            sys.exit(1)

        print(f"Wrote {len(entries)} entries to {REMOTE}")


    if __name__ == "__main__":
        main()
  '';
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
