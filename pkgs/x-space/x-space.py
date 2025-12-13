#!/usr/bin/env -S uv run --script --quiet
"""Download X Spaces recordings."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "sh",
# ]
# ///


import os
import sys
from sh import yt_dlp, wget, aria2c, ffmpeg, ErrorReturnCode
import tempfile
import shutil
import re
import atexit
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('stream_url', help='URL of the X/Twitter Space stream')
args = parser.parse_args()

space_url = args.stream_url
original_dir = os.getcwd()

# Get filename using yt-dlp
try:
    file_name = yt_dlp(
        '--cookies-from-browser', 'chrome', '--get-filename',
        '-o', '%(upload_date)s - %(uploader_id)s.%(title)s.%(id)s.%(ext)s',
        space_url
    ).strip()
except ErrorReturnCode:
    print("Failed to get filename from yt-dlp")
    sys.exit(1)

with tempfile.TemporaryDirectory() as tmp_dir:
    os.chdir(tmp_dir)

    def cleanup():
        files_to_remove = ['stream.m3u8', 'modified.m3u8']
        for file in files_to_remove:
            if os.path.exists(file):
                os.remove(file)

        for aac_file in [f for f in os.listdir('.') if f.endswith('.aac')]:
            os.remove(aac_file)

        os.chdir(original_dir)

    atexit.register(cleanup)

    # Get stream URL
    try:
        stream = yt_dlp(
            '--cookies-from-browser', 'chrome', '-g', space_url
        ).strip()
    except ErrorReturnCode:
        print("Failed to get stream URL")
        sys.exit(1)

    # Extract stream path
    stream_path_match = re.match(r'^.*/', stream)
    if not stream_path_match:
        print("Failed to extract stream path")
        sys.exit(1)
    stream_path = stream_path_match.group(0)

    # Download stream manifest
    try:
        wget('-q', '-O', 'stream.m3u8', stream)
    except ErrorReturnCode:
        print("Failed to download the stream.")
        sys.exit(1)

    # Modify m3u8 file
    with open('stream.m3u8', 'r') as stream_file, open('modified.m3u8', 'w') as modified_file:
        for line in stream_file:
            line = line.rstrip('\n')
            if re.match(r'^[^.#]+\.aac$', line):
                modified_file.write(f"{stream_path}{line}\n")
            else:
                modified_file.write(f"{line}\n")

    # Download segments and convert
    aria2c('-i', 'modified.m3u8')
    ffmpeg('-i', 'stream.m3u8', '-c', 'copy', file_name)

    # Move file to original directory
    shutil.move(file_name, original_dir)

# Check if file was successfully downloaded
final_path = os.path.join(original_dir, file_name)
if os.path.exists(final_path):
    print(f"File downloaded and saved in the original directory: {file_name}")
else:
    print("Failed to download the file.")