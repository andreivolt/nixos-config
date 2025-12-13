#!/usr/bin/env -S uv run --script --quiet
"""Transcribe audio using Lightning Whisper MLX with GPU support."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "lightning-whisper-mlx",
# ]
# ///

import sys
import argparse
from lightning_whisper_mlx import LightningWhisperMLX

parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('audio_file', help='Audio file to transcribe')
parser.add_argument('--model', default='base', choices=['tiny', 'base', 'small', 'medium', 'large', 'large-v2', 'large-v3'],
                   help='Whisper model size')
parser.add_argument('--output', '-o', help='Output file (default: stdout)')
args = parser.parse_args()

try:
    whisper = LightningWhisperMLX(model=args.model, batch_size=12, quant=None)
    result = whisper.transcribe(audio_path=args.audio_file)

    text = result['text']

    if args.output:
        with open(args.output, 'w') as f:
            f.write(text)
        print(f'Transcribed to {args.output}', file=sys.stderr)
    else:
        print(text)

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
