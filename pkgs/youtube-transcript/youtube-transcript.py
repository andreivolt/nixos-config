#!/usr/bin/env -S uv run --script --quiet
"""Extract and process YouTube video transcripts and captions."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "browser-cookie3",
#   "joblib",
#   "lxml",
#   "platformdirs",
#   "requests",
#   "sh",
#   "tiktoken",
#   "youtube-transcript-api>=0.6.2",
#   "yt-dlp",
# ]
# ///


import sys
import re
import json
from pathlib import Path
from urllib.parse import urlparse, parse_qs
from youtube_transcript_api import YouTubeTranscriptApi
import argparse
from platformdirs import user_cache_dir
from joblib import Memory
import tiktoken
import sh
import browser_cookie3

# Initialize persistent cache
cache_dir = user_cache_dir("youtube-transcript")
memory = Memory(cache_dir, verbose=0)

# Initialize tokenizer (using GPT-4 encoding as default)
tokenizer = tiktoken.get_encoding("cl100k_base")

def get_video_id(url_or_id):
    if re.match(r'[a-zA-Z0-9_-]{11}$', url_or_id):
        return url_or_id
    else:
        parsed_url = urlparse(url_or_id)

        # Handle youtu.be format
        if 'youtu.be' in parsed_url.netloc:
            return parsed_url.path.lstrip('/')

        # Handle youtube.com format
        query_params = parse_qs(parsed_url.query)
        video_id_list = query_params.get('v', [])
        if video_id_list:
            return video_id_list[0]

        raise ValueError("Could not extract video ID from URL")

def format_timestamp(seconds):
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    seconds = int(seconds % 60)
    if hours > 0:
        return f"{hours}:{minutes:02d}:{seconds:02d}"
    else:
        return f"{minutes}:{seconds:02d}"

@memory.cache
def get_transcript_with_ytdlp(video_id):
    """Fallback method using yt-dlp to get transcript"""
    try:
        # Build yt-dlp command - use JSON output for subtitles
        cookies_file = Path.home() / ".config/youtube/cookies.txt"
        cmd_args = [
            '--write-auto-subs', '--skip-download', '--write-sub', '--sub-format', 'json3',
            '--sub-langs', 'en',
            '-o', f'{video_id}', f'https://www.youtube.com/watch?v={video_id}'
        ]
        if cookies_file.exists():
            cmd_args.extend(['--cookies', str(cookies_file)])

        sh.yt_dlp(*cmd_args, _cwd=str(Path.cwd()))

        # Look for generated JSON subtitle file
        json_file = Path.cwd() / f"{video_id}.en.json3"
        if json_file.exists():
            with open(json_file, 'r', encoding='utf-8') as f:
                subtitle_data = json.load(f)

            # Convert JSON subtitle format to transcript format
            transcript = []
            events = subtitle_data.get('events', [])

            for event in events:
                if 'segs' in event:
                    start_time = event.get('tStartMs', 0) / 1000.0  # Convert ms to seconds
                    text_parts = []
                    for seg in event['segs']:
                        if 'utf8' in seg:
                            text_parts.append(seg['utf8'])

                    if text_parts:
                        full_text = ''.join(text_parts).strip()
                        if full_text:
                            transcript.append({'text': full_text, 'start': start_time})

            # Clean up JSON file
            json_file.unlink(missing_ok=True)
            return transcript if transcript else None
        else:
            return None

    except Exception as e:
        return None

def chunk_text(text, max_tokens=60000):
    """Chunk text to fit within model's output limit using tiktoken (65,536 tokens for Gemini 2.5 Flash, leaving room for formatting)"""
    tokens = tokenizer.encode(text)

    chunks = []
    for i in range(0, len(tokens), max_tokens):
        chunk_tokens = tokens[i:i + max_tokens]
        chunk_text = tokenizer.decode(chunk_tokens)
        chunks.append(chunk_text)

    return chunks

@memory.cache
def split_into_paragraphs(text):
    """Split transcript text into meaningful paragraphs using Gemini 2.5 Flash"""
    chunks = chunk_text(text)
    processed_chunks = []

    for chunk in chunks:
        prompt = """Split this YouTube transcript into meaningful paragraphs. Each paragraph should represent a coherent topic or thought. Return only the formatted text with proper paragraph breaks (double newlines between paragraphs).

Transcript:
""" + chunk

        result = sh.llm('prompt', '-m', 'gemini-2.5-flash-preview-05-20', '--no-log', prompt)
        processed_chunks.append(result.strip())

    return '\n\n'.join(processed_chunks)

@memory.cache
def get_transcript_with_deepgram(url):
    """Get transcript using youtube-audio and deepgram"""
    try:
        # Get audio using youtube-audio and pipe to deepgram via with-uploaded-file
        youtube_audio = sh.Command('youtube-audio')
        with_uploaded_file = sh.Command('with-uploaded-file')
        deepgram = sh.Command('deepgram')

        # Chain the commands: youtube-audio $url | with-uploaded-file deepgram
        audio_output = youtube_audio(url)
        transcript_text = with_uploaded_file(deepgram, _in=audio_output)

        # Return in format compatible with other methods
        return [{'text': transcript_text.strip(), 'start': 0}]

    except Exception as e:
        raise Exception(f"Failed to get transcript with deepgram: {str(e)}")

@memory.cache
def get_transcript(video_id):
    """Get transcript for video ID"""
    import requests
    from http.cookiejar import MozillaCookieJar

    http_client = requests.Session()
    cookies_file = Path.home() / ".config/youtube/cookies.txt"

    if cookies_file.exists():
        jar = MozillaCookieJar(cookies_file)
        jar.load()
        http_client.cookies = jar
    else:
        try:
            cookies = browser_cookie3.chrome()
            for cookie in cookies:
                http_client.cookies.set_cookie(cookie)
        except:
            pass

    # Create API instance with cookies
    api = YouTubeTranscriptApi(http_client=http_client)

    # Try to get English transcript first
    try:
        return api.fetch(video_id, languages=['en'])
    except Exception as e:
        # If English transcript is not available, get list of available transcripts
        try:
            transcript_list = api.list(video_id)

            # Try to get the first auto-generated transcript available
            generated_transcripts = [t for t in transcript_list if t.is_generated]
            if generated_transcripts:
                return generated_transcripts[0].fetch()
            else:
                # If no auto-generated transcript, try any available transcript
                available_transcript = next(iter(transcript_list), None)
                if available_transcript:
                    return available_transcript.fetch()
                else:
                    raise Exception("No transcripts found for this video")
        except Exception as inner_e:
            # Try yt-dlp fallback when YouTube API fails
            transcript = get_transcript_with_ytdlp(video_id)
            if transcript is None:
                raise Exception(f"Failed to get transcript with both methods. YouTube API error: {inner_e}")
            return transcript

# Parse arguments
parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('url', help='YouTube URL or video ID')
parser.add_argument('--timestamps', action='store_true', help='Include timestamps')
parser.add_argument('--paragraphs', action='store_true', help='Split transcript into meaningful paragraphs using 4o-mini model')
parser.add_argument('--deepgram', action='store_true', help='Use youtube-audio and deepgram for transcript generation')
args = parser.parse_args()

try:
    if args.deepgram:
        transcript = get_transcript_with_deepgram(args.url)
    else:
        video_id = get_video_id(args.url)
        transcript = get_transcript(video_id)

    if args.timestamps:
        for entry in transcript:
            # Handle both dict and object access patterns
            if hasattr(entry, 'start'):
                timestamp = format_timestamp(entry.start)
                text = entry.text
            else:
                timestamp = format_timestamp(entry['start'])
                text = entry['text']
            print(f"[{timestamp}] {text}")
    else:
        # Handle both dict and object access patterns

        if transcript and hasattr(transcript[0], 'text'):
            text = ' '.join([entry.text for entry in transcript])
        else:
            text = ' '.join([entry['text'] for entry in transcript])

        if args.paragraphs:
            text = split_into_paragraphs(text)

        print(text)
except Exception as e:
    print(f"Error: {str(e)}")
    sys.exit(1)