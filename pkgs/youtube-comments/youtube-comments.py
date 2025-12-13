#!/usr/bin/env -S uv run --script --quiet
"""Fetch and display YouTube video comments."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "joblib",
#   "platformdirs",
#   "requests",
#   "rich>=13.0",
#   "sh",
# ]
# ///

import os
import sys
import argparse
import html
import re
import requests
import json
import hashlib
import time
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Optional, Any
from urllib.parse import urlparse, parse_qs
from platformdirs import user_cache_dir
from joblib import Memory


# Initialize persistent cache
cache_dir = user_cache_dir("youtube-comments")
memory = Memory(cache_dir, verbose=0)


def extract_video_id(input_str: str) -> str:
    """Extract video ID from YouTube URL or return as-is if already an ID."""
    # If it looks like a video ID (11 chars, alphanumeric with - and _), return as is
    if re.match(r'^[a-zA-Z0-9_-]{11}$', input_str):
        return input_str

    # Try to parse as URL
    parsed = urlparse(input_str)

    # Handle youtu.be URLs
    if parsed.netloc in ('youtu.be', 'www.youtu.be'):
        return parsed.path.lstrip('/')

    # Handle youtube.com URLs
    if parsed.netloc in ('youtube.com', 'www.youtube.com', 'm.youtube.com'):
        if parsed.path == '/watch':
            # Extract from query parameter
            video_id = parse_qs(parsed.query).get('v')
            if video_id:
                return video_id[0]
        elif parsed.path.startswith('/embed/'):
            # Extract from embed URL
            return parsed.path.replace('/embed/', '')
        elif parsed.path.startswith('/v/'):
            # Extract from /v/ URL
            return parsed.path.replace('/v/', '')

    # If we couldn't extract, return the original input
    return input_str


def clean_username(username: str) -> str:
    """Remove @ symbols from username."""
    return re.sub(r'^@@?', '', username or '')


def clean_text(text: str) -> str:
    """Clean and format comment text."""
    if not text:
        return ''

    # Unescape HTML entities
    text = html.unescape(text)

    # Replace <br> tags with newlines
    text = text.replace('<br><br>', '\n\n').replace('<br>', '\n')

    # Remove @ mentions at the start of the text
    text = re.sub(r'^@@?\w+\s+', '', text)

    return text.strip()


def format_time_with_relative(iso_timestamp: str) -> tuple[str, str]:
    """Format ISO timestamp to show both full datetime and relative time."""
    try:
        # Parse the ISO timestamp
        dt = datetime.fromisoformat(iso_timestamp.replace('Z', '+00:00'))

        # Format as full datetime (similar to HN's format)
        full_time = dt.strftime('%Y-%m-%d %H:%M:%S UTC')

        # Calculate relative time
        now = datetime.now(timezone.utc)
        diff = now - dt.replace(tzinfo=timezone.utc)

        if diff.days > 0:
            relative = f"{diff.days} day{'s' if diff.days != 1 else ''} ago"
        elif diff.seconds > 3600:
            hours = diff.seconds // 3600
            relative = f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif diff.seconds > 60:
            minutes = diff.seconds // 60
            relative = f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        else:
            relative = "just now"

        return full_time, relative
    except:
        # Fallback to original timestamp
        return iso_timestamp, iso_timestamp


def organize_replies(replies: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Organize replies into a conversation tree for tree rendering."""
    conversation = []
    reply_map = {}

    # First pass: Create a map of replies and initialize conversation
    for reply in replies:
        full_time, relative_time = format_time_with_relative(reply['date'])
        reply_map[reply['id']] = {
            'id': reply['id'],
            'author': clean_username(reply['author']),
            'time': full_time,
            'timeAgo': relative_time,
            'text': clean_text(reply['text']),
            'children': [],
            'parent_author': None
        }

    # Second pass: Build the conversation tree
    for reply in replies:
        text = reply['text'] or ''
        parent_match = re.match(r'^@@?(\w+)', text)

        if parent_match:
            parent_author = parent_match.group(1)
            # Find the most recent comment by this author
            parent_reply = None
            for r in reversed(list(reply_map.values())):
                if r['author'] == parent_author:
                    parent_reply = r
                    break

            if parent_reply:
                parent_reply['children'].append(reply_map[reply['id']])
                reply_map[reply['id']]['parent_author'] = parent_author
                continue

        # If no parent found or no @ mention, add to top level
        if not reply_map[reply['id']]['parent_author']:
            conversation.append(reply_map[reply['id']])

    return conversation


def youtube_to_tree_format(comment: Dict[str, Any]) -> Dict[str, Any]:
    """Convert YouTube comment to tree format expected by comment_tree library"""
    full_time, relative_time = format_time_with_relative(comment['date'])
    return {
        'id': str(hash(comment['author'] + comment['date'])),
        'author': comment['author'],
        'time': full_time,
        'timeAgo': relative_time,
        'text': comment['text'],
        'children': comment.get('children', [])
    }


@memory.cache
def fetch_comments(video_id: str, api_key: str) -> List[Dict[str, Any]]:
    """Fetch comments from YouTube API."""
    comments = []
    page_token = None

    while True:
        params = {
            'part': 'snippet',
            'videoId': video_id,
            'maxResults': 100,
            'key': api_key
        }
        if page_token:
            params['pageToken'] = page_token

        response = requests.get(
            'https://www.googleapis.com/youtube/v3/commentThreads',
            params=params
        )

        if not response.ok:
            break

        data = response.json()
        if 'error' in data:
            break

        for item in data.get('items', []):
            top_level_comment = item.get('snippet', {}).get('topLevelComment', {}).get('snippet')
            if not top_level_comment:
                continue

            replies = []
            if item.get('snippet', {}).get('totalReplyCount', 0) > 0:
                replies_response = requests.get(
                    'https://www.googleapis.com/youtube/v3/comments',
                    params={
                        'part': 'snippet',
                        'parentId': item['snippet']['topLevelComment']['id'],
                        'maxResults': 100,
                        'key': api_key
                    }
                )

                if replies_response.ok:
                    replies_data = replies_response.json()
                    if 'error' not in replies_data:
                        replies = [
                            {
                                'id': reply['id'],
                                'author': reply['snippet']['authorDisplayName'].strip(),
                                'date': reply['snippet']['publishedAt'],
                                'text': reply['snippet']['textDisplay']
                            }
                            for reply in replies_data.get('items', [])
                        ]

                        if replies:
                            organized_replies = organize_replies(replies)
                            comments.append({
                                'author': clean_username(top_level_comment['authorDisplayName']),
                                'date': top_level_comment['publishedAt'],
                                'text': clean_text(top_level_comment['textDisplay']),
                                'children': organized_replies if organized_replies else []
                            })
                        else:
                            # Add comment without replies
                            comments.append({
                                'author': clean_username(top_level_comment['authorDisplayName']),
                                'date': top_level_comment['publishedAt'],
                                'text': clean_text(top_level_comment['textDisplay']),
                                'children': []
                            })
                    else:
                        # Add comment without replies if replies fetch failed
                        comments.append({
                            'author': clean_username(top_level_comment['authorDisplayName']),
                            'date': top_level_comment['publishedAt'],
                            'text': clean_text(top_level_comment['textDisplay']),
                            'children': []
                        })
                else:
                    # Add comment without replies if replies fetch failed
                    comments.append({
                        'author': clean_username(top_level_comment['authorDisplayName']),
                        'date': top_level_comment['publishedAt'],
                        'text': clean_text(top_level_comment['textDisplay']),
                        'children': []
                    })
            else:
                # Add comment without replies
                comments.append({
                    'author': clean_username(top_level_comment['authorDisplayName']),
                    'date': top_level_comment['publishedAt'],
                    'text': clean_text(top_level_comment['textDisplay']),
                    'children': []
                })

        page_token = data.get('nextPageToken')
        if not page_token:
            break

    return comments


# Parse arguments
parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('video_input', nargs='?', help='YouTube video ID or URL')
parser.add_argument('--json', action='store_true', help='Output comments in JSON format')
parser.add_argument('--jsonl', action='store_true', help='Output comments in JSONL format (one line per root comment)')
parser.add_argument('--clear-cache', action='store_true', help='Clear the cache')

args = parser.parse_args()

if args.clear_cache:
    cache_path = Path(cache_dir)
    if cache_path.exists():
        shutil.rmtree(cache_path)
        print('Cache cleared.')
    else:
        print('Cache directory does not exist.')
    sys.exit(0)

if not args.video_input:
    parser.print_help()
    sys.exit(1)

api_key = os.environ.get('GOOGLE_API_KEY')
if not api_key:
    print("Error: GOOGLE_API_KEY environment variable is required", file=sys.stderr)
    sys.exit(1)

video_id = extract_video_id(args.video_input)

try:
    # Fetch comments (with caching handled by joblib)
    comments = fetch_comments(video_id, api_key)

    if args.json:
        import json

        print(json.dumps(comments, indent=2))
    elif args.jsonl:
        import json

        # Output one JSON object per line (JSONL format)
        for comment in comments:
            print(json.dumps(comment, separators=(',', ':')))
    else:
        tree_comments = [youtube_to_tree_format(comment) for comment in comments]
        # Use tree-render via sh
        import sh
        import json
        # Pass through the TTY status to tree-render's environment
        env = os.environ.copy()
        if not sys.stdout.isatty():
            env['NO_COLOR'] = '1'

        result = sh.Command('tree-render')('--author=author', '--timestamp=time', '--content=text', '--replies=children', _in=json.dumps(tree_comments), _env=env)
        print(result, end='')

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)