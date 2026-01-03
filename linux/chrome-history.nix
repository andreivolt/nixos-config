{pkgs, ...}:
let
  exportScript = pkgs.writers.writePython3 "chrome-history-export" {} ''
    import fcntl
    import os
    import shutil
    import socket
    import sqlite3
    import sys
    import tempfile
    import time
    from pathlib import Path

    WEBKIT_EPOCH_OFFSET = 11644473600
    DRIVE_DIR = Path.home() / "drive"
    OUTPUT_FILE = DRIVE_DIR / "chrome-history.tsv"
    LOCK_FILE = DRIVE_DIR / ".chrome-history.lock"
    LOCK_TIMEOUT = 120  # Consider lock stale after 2 minutes


    def webkit_to_unix(webkit_time):
        return (webkit_time / 1_000_000) - WEBKIT_EPOCH_OFFSET


    def unix_to_webkit(unix_time):
        return int((unix_time + WEBKIT_EPOCH_OFFSET) * 1_000_000)


    def format_timestamp(unix_time):
        return f"U{int(unix_time * 1000)}.{int((unix_time % 1) * 1000):03d}"


    def parse_timestamp(ts_str):
        # Parse "U1750610491522.123" -> 1750610491.522123
        if ts_str.startswith("U"):
            ts_str = ts_str[1:]
        parts = ts_str.split(".")
        ms = int(parts[0])
        frac = int(parts[1]) if len(parts) > 1 else 0
        return ms / 1000 + frac / 1_000_000


    def check_drive_available():
        """Verify drive is accessible (catches broken FUSE mounts)"""
        try:
            # stat() fails on broken FUSE mounts ("Transport endpoint is not connected")
            (OUTPUT_FILE if OUTPUT_FILE.exists() else DRIVE_DIR).stat()
            return True, None
        except OSError as e:
            return False, f"Drive not accessible: {e}"


    def acquire_lock():
        """Acquire cross-machine lock. Returns (success, lock_file_handle)"""
        hostname = socket.gethostname()
        now = time.time()

        # Check for existing lock from another machine
        if LOCK_FILE.exists():
            try:
                content = LOCK_FILE.read_text().strip()
                lock_host, lock_time = content.split(":")
                lock_age = now - float(lock_time)
                if lock_host != hostname and lock_age < LOCK_TIMEOUT:
                    return False, None, f"Locked by {lock_host} ({int(lock_age)}s ago)"
            except (ValueError, OSError):
                pass  # Corrupted lock file, proceed to overwrite

        # Write our lock
        try:
            LOCK_FILE.write_text(f"{hostname}:{now}")
            # Also use flock for same-machine protection
            lock_fh = open(LOCK_FILE, "r+")
            fcntl.flock(lock_fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            return True, lock_fh, None
        except (BlockingIOError, OSError) as e:
            return False, None, f"Could not acquire lock: {e}"


    def release_lock(lock_fh):
        """Release the lock"""
        try:
            if lock_fh:
                fcntl.flock(lock_fh.fileno(), fcntl.LOCK_UN)
                lock_fh.close()
            LOCK_FILE.unlink(missing_ok=True)
        except OSError:
            pass


    def find_history_db():
        """Find Chrome or Chromium history database"""
        candidates = [
            Path.home() / ".config" / "google-chrome" / "Default" / "History",
            Path.home() / ".config" / "chromium" / "Default" / "History",
        ]
        for path in candidates:
            if path.exists():
                return path
        return None


    def load_existing_entries():
        """Load existing entries from TSV file, returns dict of (url, webkit_time) -> line"""
        entries = {}
        if not OUTPUT_FILE.exists():
            return entries

        with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
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
        """Fetch all entries from the history database"""
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
                # Escape tabs/newlines in title
                safe_title = (title or "").replace("\t", " ").replace("\n", " ")
                line = f"{url}\t{ts_str}\t{visit_count}\t{safe_title}"
                yield (url, webkit_time), line
            conn.close()
        finally:
            os.unlink(tmp_path)


    def main():
        # Check drive is available
        available, error = check_drive_available()
        if not available:
            print(f"Drive not available: {error}")
            sys.exit(1)

        db_path = find_history_db()
        if not db_path:
            print("No Chrome/Chromium history database found")
            return

        # Acquire lock
        locked, lock_fh, error = acquire_lock()
        if not locked:
            print(f"Skipping: {error}")
            return

        try:
            # Load existing entries
            entries = load_existing_entries()
            initial_count = len(entries)

            # Safety check: if file exists and has content but we read nothing, abort
            # This catches FUSE mount returning empty content despite stat() succeeding
            if OUTPUT_FILE.exists():
                file_size = OUTPUT_FILE.stat().st_size
                if file_size > 0 and initial_count == 0:
                    print(f"SAFETY ABORT: File is {file_size} bytes but loaded 0 entries")
                    print("FUSE mount may be returning invalid content. Refusing to overwrite.")
                    sys.exit(1)

            # Merge new entries (only adds if key doesn't exist)
            for key, line in fetch_new_entries(db_path):
                if key not in entries:
                    entries[key] = line

            new_count = len(entries) - initial_count
            print(f"Found {new_count} new entries (total: {len(entries)})")

            if new_count == 0:
                return

            # Sort by webkit_time (second element of key tuple) and write atomically
            sorted_entries = sorted(entries.items(), key=lambda x: x[0][1])

            # Write to temp file first, then rename for atomicity
            tmp_output = OUTPUT_FILE.with_suffix(".tmp")
            with open(tmp_output, "w", encoding="utf-8") as f:
                for _, line in sorted_entries:
                    f.write(line + "\n")
            tmp_output.rename(OUTPUT_FILE)

            print(f"Wrote {len(entries)} entries to {OUTPUT_FILE}")
        finally:
            release_lock(lock_fh)


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
