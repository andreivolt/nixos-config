#!/usr/bin/env -S uv run --script --quiet
"""Download and convert YouTube videos to audio files."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "certifi>=2024.8",
#   "platformdirs>=4.0",
#   "sh",
#   "yt-dlp>=2024.12",
# ]
# ///


import sys
import os
import argparse
import shutil
from yt_dlp import YoutubeDL
from platformdirs import user_cache_dir

parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('url_or_id', nargs='?', help='YouTube URL or ID')
parser.add_argument('--clear-cache', action='store_true', help='Clear the cache')
parser.add_argument('--format', default='mp3', choices=['mp3', 'native'],
                   help='Output format')
args = parser.parse_args()

my_cache_dir = user_cache_dir(appname="yt_audio_cache", appauthor=False)

if args.clear_cache:
    if os.path.exists(my_cache_dir):
        shutil.rmtree(my_cache_dir)
        print('Cache cleared.')
    else:
        print('Cache directory does not exist.')
    sys.exit(0)

if not args.url_or_id:
    parser.print_help()
    sys.exit(1)

is_piped = not sys.stdout.isatty()

if not os.path.exists(my_cache_dir):
    os.makedirs(my_cache_dir)

# Configure yt-dlp options based on format choice
if args.format == 'mp3':
    # Convert to MP3 for maximum compatibility
    ydl_opts = {
        'format': '141/140/251/bestaudio[ext=m4a]/bestaudio',
        'outtmpl': os.path.join(my_cache_dir, '%(id)s.%(ext)s'),
        'quiet': True,
        'keepvideo': False,
        # Convert to MP3
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }],
        'prefer_ffmpeg': True,
    }
else:
    # Keep native format
    ydl_opts = {
        'format': '141/140/251/bestaudio[ext=m4a]/bestaudio',
        'outtmpl': os.path.join(my_cache_dir, '%(id)s.%(ext)s'),
        'quiet': True,
        'keepvideo': False,
        'postprocessors': [],
    }

try:
    ydl = YoutubeDL(ydl_opts)
    info = ydl.extract_info(args.url_or_id, download=True)
    video_id = info.get('id')

    # Get the actual downloaded file
    # When converting to MP3, the extension will be .mp3
    if args.format == 'mp3':
        cached_filename = f'{video_id}.mp3'
    else:
        files = [f for f in os.listdir(my_cache_dir) if f.startswith(video_id + '.')]
        if not files:
            print("Error: Couldn't find downloaded file", file=sys.stderr)
            sys.exit(1)
        cached_filename = files[0]

    cached_file = os.path.join(my_cache_dir, cached_filename)

    if is_piped:
        with open(cached_file, 'rb') as f:
            shutil.copyfileobj(f, sys.stdout.buffer)
    else:
        # Keep original extension to preserve format

        output_filename = f'{video_id}{os.path.splitext(cached_filename)[1]}'
        shutil.copyfile(cached_file, output_filename)
        print(f'Downloaded audio to {output_filename}')

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)