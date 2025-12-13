#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "sh",
# ]
# ///

import argparse
import sys
import re
from pathlib import Path
from sh import llm, file as file_cmd, ErrorReturnCode

parser = argparse.ArgumentParser(description="Rename file based on AI-generated description")
parser.add_argument("file", help="File path to rename")
parser.add_argument("-y", "--yes", action="store_true", help="Skip confirmation")
parser.add_argument("-m", "--model", default="openrouter/anthropic/claude-haiku-4.5", help="Vision model (default: openrouter/anthropic/claude-haiku-4.5)")
args = parser.parse_args()

file_path = Path(args.file).resolve()

if not file_path.exists():
    print(f"Error: File not found: {file_path}", file=sys.stderr)
    sys.exit(1)

# Detect MIME type
mime_type = file_cmd("--brief", "--mime-type", str(file_path)).strip()

# Supported mime types for attachments
SUPPORTED_ATTACHMENT_TYPES = {
    'application/pdf',
    'image/png',
    'image/webp',
    'image/gif',
    'image/jpeg'
}

try:
    # Always analyze content to get best name
    if mime_type in SUPPORTED_ATTACHMENT_TYPES:
        description = llm("-m", args.model, "-n",
                         "Describe this file in 5-10 words for generating a filename.",
                         "--at", str(file_path), mime_type).strip()
    elif mime_type.startswith('text/') or 'json' in mime_type or 'xml' in mime_type:
        # Text-based files
        content = file_path.read_text(errors='ignore')[:2000]
        description = llm("-m", args.model, "-n", f"Describe this content in 5-10 words for a filename:\n\n{content}").strip()
    else:
        # Documents, PDFs, etc - use 2text
        try:
            from sh import Command
            two_text = Command("2text")
            content = two_text(str(file_path)).strip()[:2000]
            description = llm("-m", args.model, "-n", f"Describe this content in 5-10 words for a filename:\n\n{content}").strip()
        except:
            # Fallback: use current filename as basis
            description = file_path.stem

    # Generate maximally evocative compressed kebab-case filename
    format_prompt = f"Convert to maximally compressed yet evocative kebab-case filename (no extension). Use the fewest words that still clearly convey what the file contains. Text: {description}"
    new_name = llm("-m", args.model, "-n", format_prompt).strip()

    # Cleanup to kebab-case
    new_name = re.sub(r'[^\w\s-]', '', new_name).lower()
    new_name = re.sub(r'[-\s]+', '-', new_name).strip('-')

    # Check if names are essentially the same (case-insensitive, normalized)
    current_normalized = re.sub(r'[^\w]', '', file_path.stem).lower()
    new_normalized = re.sub(r'[^\w]', '', new_name).lower()

    if current_normalized == new_normalized:
        print(f"Filename '{file_path.name}' is already optimal")
        sys.exit(0)

    if not new_name:
        raise ValueError("Empty filename generated")

    # Handle conflicts with numeric suffix
    base_new_path = file_path.parent / (new_name + file_path.suffix)
    new_path = base_new_path
    suffix_num = 2

    while new_path.exists() and new_path != file_path:
        new_path = file_path.parent / f"{new_name}-{suffix_num}{file_path.suffix}"
        suffix_num += 1

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)

# Show changes
print(f"Current: {file_path.name}")
print(f"New:     {new_path.name}")

if not args.yes:
    response = input("Rename? [y/N] ").strip().lower()
    if response not in ['y', 'yes']:
        print("Cancelled")
        sys.exit(0)

file_path.rename(new_path)
print(f"✓ Renamed to: {new_path.name}")
