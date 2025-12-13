#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "yt-dlp"
# ]
# ///

import argparse
import sys
from yt_dlp import YoutubeDL

parser = argparse.ArgumentParser(description='Search YouTube videos')
parser.add_argument('query', help='Search query')
parser.add_argument('--limit', type=int, help='Limit number of results (default: 1000)')
args = parser.parse_args()

limit = args.limit if args.limit else 1000

ydl_opts = {
    'quiet': True,
    'no_warnings': True,
    'extract_flat': True,
}

search_query = f"ytsearch{limit}:{args.query}"

with YoutubeDL(ydl_opts) as ydl:
    try:
        info = ydl.extract_info(search_query, download=False)

        if 'entries' not in info:
            print(f"Error: No videos found", file=sys.stderr)
            sys.exit(1)

        for entry in info['entries']:
            if entry:
                title = entry.get('title', 'N/A')
                video_id = entry.get('id', '')
                url = f"https://youtube.com/watch?v={video_id}" if video_id else 'N/A'
                print(f"{title}\t{url}")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
