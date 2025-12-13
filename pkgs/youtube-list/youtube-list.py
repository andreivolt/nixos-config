#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "yt-dlp",
#   "platformdirs",
#   "joblib"
# ]
# ///

import argparse
import os
import shutil
import sys
from yt_dlp import YoutubeDL
from platformdirs import user_cache_dir
from joblib import Memory

parser = argparse.ArgumentParser(description='List YouTube videos from a channel')
parser.add_argument('channel', nargs='?', help='YouTube channel URL or ID')
parser.add_argument('--limit', type=int, help='Limit number of videos to fetch')
parser.add_argument('--type', choices=['all', 'videos', 'shorts', 'streams'], default='all',
                    help='Type of content to list (default: all)')
parser.add_argument('-x', '--clear-cache', action='store_true', help='Clear the cache')
args = parser.parse_args()

cache_dir = user_cache_dir(appname="youtube_list", appauthor=False)
memory = Memory(cache_dir, verbose=0)

if args.clear_cache:
    if os.path.exists(cache_dir):
        shutil.rmtree(cache_dir)
        print('Cache cleared.')
    else:
        print('Cache directory does not exist.')
    sys.exit(0)

if not args.channel:
    parser.print_help()
    sys.exit(1)

@memory.cache
def fetch_channel_info(channel_url, limit):
    """Fetch channel info with caching"""
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': 'in_playlist',
        'playlistend': limit,
    }
    with YoutubeDL(ydl_opts) as ydl:
        return ydl.extract_info(channel_url, download=False)

# Ensure we get the full channel URL with the right tab
channel_url = args.channel
if not channel_url.startswith('http'):
    channel_url = f'https://youtube.com/{channel_url}'

# Append the appropriate tab based on type
if '/videos' not in channel_url and '/streams' not in channel_url and '/shorts' not in channel_url:
    if args.type == 'videos':
        channel_url += '/videos'
    elif args.type == 'shorts':
        channel_url += '/shorts'
    elif args.type == 'streams':
        channel_url += '/streams'
    else:  # all - fetch from videos tab which usually has everything
        channel_url += '/videos'

try:
    info = fetch_channel_info(channel_url, args.limit)

    if 'entries' not in info:
        print(f"Error: No videos found or invalid channel URL", file=sys.stderr)
        sys.exit(1)

    for entry in info['entries']:
        if entry is None:
            continue

        title = entry.get('title', 'N/A')
        video_id = entry.get('id', '')
        url = f"https://youtube.com/watch?v={video_id}" if video_id else 'N/A'

        print(f"{title}\t{url}")

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
