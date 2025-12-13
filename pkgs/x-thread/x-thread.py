#!/usr/bin/env -S uv run --script --quiet
"""Scrape and display X/Twitter threads."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "diskcache",
#   "platformdirs",
#   "sh",
#   "twscrape",
# ]
# ///


import argparse
import asyncio
import json
import re
import sys
from pathlib import Path

import diskcache
from platformdirs import user_cache_dir

# Initialize cache
cache = diskcache.Cache(user_cache_dir("x-thread"))

def extract_thread_id(url_or_id):
    """Extract thread ID from X/Twitter URL or return the ID if already provided."""
    if url_or_id.isdigit():
        return url_or_id

    # Match various X/Twitter URL patterns
    patterns = [
        r'(?:twitter\.com|x\.com)/\w+/status/(\d+)',
        r'(?:twitter\.com|x\.com)/i/web/status/(\d+)',
        r'(?:mobile\.twitter\.com|mobile\.x\.com)/\w+/status/(\d+)',
    ]

    for pattern in patterns:
        match = re.search(pattern, url_or_id)
        if match:
            return match.group(1)

    raise ValueError(f"Could not extract thread ID from: {url_or_id}")

async def get_thread_data(thread_id, account_db_path):
    """Download thread data using twscrape with caching."""
    # Create cache key
    cache_key = f"{thread_id}:{Path(account_db_path).resolve()}"

    # Check cache first
    if cache_key in cache:
        return cache[cache_key]
    from twscrape import API

    # Initialize API with custom database path
    api = API(str(account_db_path))

    # Get the main tweet
    try:
        main_tweet = await api.tweet_details(int(thread_id))
        if not main_tweet:
            raise ValueError(f"Could not find tweet with ID: {thread_id}")
    except Exception as e:
        raise ValueError(f"Error fetching tweet {thread_id}: {e}")

    # Get conversation tweets
    conversation_tweets = []
    try:
        async for tweet in api.search(f"conversation_id:{thread_id}", limit=200):
            conversation_tweets.append(tweet)
    except Exception as e:
        print(f"Warning: Could not fetch full conversation: {e}", file=sys.stderr)

    # Combine main tweet with conversation
    all_tweets = [main_tweet] + conversation_tweets

    # Remove duplicates by ID
    seen_ids = set()
    unique_tweets = []
    for tweet in all_tweets:
        if tweet.id not in seen_ids:
            unique_tweets.append(tweet)
            seen_ids.add(tweet.id)

    # Serialize tweets for caching
    serialized_tweets = []
    for tweet in unique_tweets:
        serialized_tweets.append({
            'id': tweet.id,
            'username': tweet.user.username,
            'date': tweet.date.isoformat(),
            'rawContent': tweet.rawContent,
            'inReplyToTweetId': getattr(tweet, 'inReplyToTweetId', None)
        })

    # Store in cache
    cache[cache_key] = serialized_tweets

    return serialized_tweets

async def get_processed_thread_data(thread_id, account_db_path):
    """Get thread data and convert to tweet-like objects."""
    serialized_tweets = await get_thread_data(thread_id, account_db_path)

    # Convert serialized data back to tweet-like objects
    class TweetLike:
        def __init__(self, data):
            self.id = data['id']
            self.rawContent = data['rawContent']
            self.inReplyToTweetId = data['inReplyToTweetId']
            from datetime import datetime
            self.date = datetime.fromisoformat(data['date'])
            self.user = type('User', (), {'username': data['username']})()

    return [TweetLike(tweet_data) for tweet_data in serialized_tweets]

def clean_reply_text(text, reply_to_username):
    """Remove @mention from reply text if it's at the beginning."""
    if not text or not reply_to_username:
        return text

    # Remove @username mention at the beginning of replies
    import re
    pattern = r'^@' + re.escape(reply_to_username) + r'\s+'
    cleaned = re.sub(pattern, '', text)
    return cleaned

def build_comment_tree(tweets):
    """Build a comment tree structure from tweets."""
    # Create a map of tweet ID to tweet data
    tweet_map = {}
    username_map = {}

    # First pass: build username map
    for tweet in tweets:
        username_map[tweet.id] = tweet.user.username

    # Second pass: build tweet map with cleaned text
    for tweet in tweets:
        reply_to_id = getattr(tweet, 'inReplyToTweetId', None)
        reply_to_username = username_map.get(reply_to_id) if reply_to_id else None

        cleaned_text = clean_reply_text(tweet.rawContent, reply_to_username)

        tweet_map[tweet.id] = {
            'id': tweet.id,
            'author': tweet.user.username,
            'time': tweet.date.strftime('%Y-%m-%d %H:%M'),
            'text': cleaned_text,
            'reply_to': reply_to_id,
            'children': []
        }

    # Build the tree structure
    root_tweets = []
    for tweet_id, tweet_data in tweet_map.items():
        reply_to = tweet_data['reply_to']
        if reply_to and reply_to in tweet_map:
            # This is a reply to another tweet in our set
            tweet_map[reply_to]['children'].append(tweet_data)
        else:
            # This is a root tweet (either the main tweet or a quote/unconnected reply)
            root_tweets.append(tweet_data)

    # Sort root tweets by time
    root_tweets.sort(key=lambda x: x['time'])

    # Sort children recursively
    def sort_children(tweet_data):
        tweet_data['children'].sort(key=lambda x: x['time'])
        for child in tweet_data['children']:
            sort_children(child)

    for tweet in root_tweets:
        sort_children(tweet)

    return root_tweets

async def main():
    parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('thread', help='X/Twitter thread URL or thread ID')
    parser.add_argument('--account-db', default='~/drive/twscrape/accounts.db',
                       help='Path to twscrape accounts database')
    parser.add_argument('--json', action='store_true',
                       help='Output raw JSON data')

    args = parser.parse_args()

    try:
        thread_id = extract_thread_id(args.thread)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    account_db_path = Path(args.account_db).expanduser()
    if not account_db_path.exists():
        print(f"Error: Account database not found at {account_db_path}", file=sys.stderr)
        sys.exit(1)

    try:
        tweets = await get_processed_thread_data(thread_id, account_db_path)

        if args.json:
            # Output raw tweet data as JSON
            tweet_data = []
            for tweet in tweets:
                tweet_data.append({
                    'id': tweet.id,
                    'author': tweet.user.username,
                    'time': tweet.date.isoformat(),
                    'text': tweet.rawContent,
                    'reply_to': getattr(tweet, 'inReplyToTweetId', None)
                })
            print(json.dumps(tweet_data, indent=2))
            sys.stdout.flush()
        else:
            # Build and display comment tree
            comment_tree = build_comment_tree(tweets)
            if comment_tree:
                # Use tree-render via sh
                import sh
                print(sh.Command('tree-render')('--author=author', '--timestamp=time', '--content=text', '--replies=children', _in=json.dumps(comment_tree)), end='')
            else:
                print("No tweets found in thread.")
                sys.stdout.flush()

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
