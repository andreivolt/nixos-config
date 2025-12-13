#!/usr/bin/env -S uv run --script --quiet
"""Dub video or audio files using ElevenLabs API."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "elevenlabs~=2.1",
# ]
# ///


import argparse
import os
import sys
import time
from pathlib import Path
from elevenlabs import ElevenLabs

parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('file', help='Video or audio file to dub')
parser.add_argument('-o', '--output', help='Output file (default: adds _dubbed suffix)')
parser.add_argument('--target-lang', required=True, help='Target language code (e.g., "es", "fr", "de", "ja")')
parser.add_argument('--source-lang', default='auto', help='Source language (default: auto-detect)')
parser.add_argument('--num-speakers', type=int, default=0, help='Number of speakers (0 for auto-detect)')
parser.add_argument('--watermark', action='store_true', help='Add watermark to output video')
parser.add_argument('--list-languages', action='store_true', help='List common language codes')
args = parser.parse_args()

# Common language codes for dubbing
LANGUAGE_CODES = {
    'en': 'English',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'de': 'German (Deutsch)',
    'it': 'Italian (Italiano)',
    'pt': 'Portuguese (Português)',
    'pl': 'Polish (Polski)',
    'nl': 'Dutch (Nederlands)',
    'sv': 'Swedish (Svenska)',
    'cs': 'Czech (Čeština)',
    'tr': 'Turkish (Türkçe)',
    'ru': 'Russian (Русский)',
    'zh': 'Chinese (中文)',
    'ja': 'Japanese (日本語)',
    'ko': 'Korean (한국어)',
    'ar': 'Arabic (العربية)',
    'hi': 'Hindi (हिन्दी)',
    'hu': 'Hungarian (Magyar)',
    'el': 'Greek (Ελληνικά)',
    'da': 'Danish (Dansk)',
    'fi': 'Finnish (Suomi)',
    'no': 'Norwegian (Norsk)',
    'uk': 'Ukrainian (Українська)',
    'bg': 'Bulgarian (Български)',
    'hr': 'Croatian (Hrvatski)',
    'sk': 'Slovak (Slovenčina)',
    'id': 'Indonesian (Bahasa Indonesia)',
    'ms': 'Malay (Bahasa Melayu)',
    'vi': 'Vietnamese (Tiếng Việt)',
    'th': 'Thai (ไทย)',
    'he': 'Hebrew (עברית)',
    'lt': 'Lithuanian (Lietuvių)',
    'lv': 'Latvian (Latviešu)',
    'et': 'Estonian (Eesti)',
    'sl': 'Slovenian (Slovenščina)',
    'fa': 'Persian (فارسی)',
    'bn': 'Bengali (বাংলা)',
    'ta': 'Tamil (தமிழ்)',
    'te': 'Telugu (తెలుగు)',
    'mr': 'Marathi (मराठी)',
    'ur': 'Urdu (اردو)',
    'gu': 'Gujarati (ગુજરાતી)',
    'kn': 'Kannada (ಕನ್ನಡ)',
    'ml': 'Malayalam (മലയാളം)',
    'pa': 'Punjabi (ਪੰਜਾਬੀ)',
}

if args.list_languages:
    print("Common language codes for ElevenLabs dubbing:")
    print("-" * 50)
    for code, name in sorted(LANGUAGE_CODES.items()):
        print(f"{code}: {name}")
    sys.exit(0)

# Check if file exists
if not Path(args.file).exists():
    print(f"Error: File not found: {args.file}", file=sys.stderr)
    sys.exit(1)

# Set up output path
if args.output:
    output_path = args.output
else:
    input_path = Path(args.file)
    output_path = input_path.parent / f"{input_path.stem}_dubbed{input_path.suffix}"

# Check API key
api_key = os.environ.get('ELEVENLABS_API_KEY')
if not api_key:
    print("Error: ELEVENLABS_API_KEY environment variable not set", file=sys.stderr)
    sys.exit(1)

client = ElevenLabs(api_key=api_key)

def dub_file(file_path, output_path, source_lang='auto', target_lang=None, num_speakers=0, watermark=False):
    """Dub a video or audio file using ElevenLabs' native dubbing API."""
    print(f"Starting dubbing process for: {file_path}")
    print(f"Source language: {source_lang}")
    print(f"Target language: {target_lang}")

    try:
        # Create dubbing job
        print("Creating dubbing job...")
        with open(file_path, 'rb') as media_file:
            result = client.dubbing.dub_a_video_or_an_audio_file(
                file=media_file,
                source_lang=source_lang,
                target_lang=target_lang,
                num_speakers=num_speakers,
                watermark=watermark
            )

        dubbing_id = result.dubbing_id
        print(f"Dubbing job created with ID: {dubbing_id}")
        print(f"Expected duration: {result.expected_duration_sec} seconds")

        # Poll for completion
        print("Waiting for dubbing to complete...")
        while True:
            try:
                status = client.dubbing.get_dubbing_project_metadata(dubbing_id)

                if hasattr(status, 'status'):
                    if status.status == 'completed':
                        print("Dubbing completed!")
                        break
                    elif status.status == 'failed':
                        print("Dubbing failed!", file=sys.stderr)
                        if hasattr(status, 'error_message'):
                            print(f"Error: {status.error_message}", file=sys.stderr)
                        sys.exit(1)
                    else:
                        print(f"Status: {status.status}...")

                time.sleep(5)  # Wait 5 seconds before checking again

            except Exception as e:
                print(f"Error checking status: {e}")
                time.sleep(5)

        # Download the dubbed file
        print("Downloading dubbed file...")
        dubbed_file = client.dubbing.download_dubbed_file(dubbing_id, language_code=target_lang)

        # Save to output file
        with open(output_path, 'wb') as f:
            f.write(dubbed_file)

        print(f"Dubbing complete! Output saved to: {output_path}")

    except Exception as e:
        print(f"Error during dubbing: {e}", file=sys.stderr)
        sys.exit(1)

# Start dubbing
dub_file(
    file_path=args.file,
    output_path=output_path,
    source_lang=args.source_lang,
    target_lang=args.target_lang,
    num_speakers=args.num_speakers,
    watermark=args.watermark
)