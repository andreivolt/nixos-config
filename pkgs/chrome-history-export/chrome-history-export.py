#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import sqlite3
import sys
from datetime import datetime

WEBKIT_EPOCH_OFFSET = 11644473600
LAST_TIMESTAMP = 1750610491.522

def webkit_to_unix(webkit_time):
    """Convert Chrome's WebKit timestamp to Unix timestamp"""
    return (webkit_time / 1_000_000) - WEBKIT_EPOCH_OFFSET

def main():
    db_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/chrome-history-copy.db"

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    query = """
        SELECT visits.visit_time, urls.url, urls.visit_count, urls.title
        FROM urls
        INNER JOIN visits ON urls.id = visits.url
        WHERE visits.visit_time > ?
        ORDER BY visits.visit_time ASC
    """

    webkit_threshold = int((LAST_TIMESTAMP + WEBKIT_EPOCH_OFFSET) * 1_000_000)

    cursor.execute(query, (webkit_threshold,))

    for webkit_time, url, visit_count, title in cursor:
        unix_time = webkit_to_unix(webkit_time)
        timestamp_str = f"U{int(unix_time * 1000)}.{int((unix_time % 1) * 1000):03d}"
        print(f"{url}\t{timestamp_str}\t{visit_count}\t{title}")

    conn.close()

if __name__ == "__main__":
    main()
