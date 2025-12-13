#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "tiktoken",
# ]
# ///

import sys
import argparse
import subprocess
import tiktoken
from concurrent.futures import ThreadPoolExecutor, as_completed

def count_tokens(text, encoding):
    return len(encoding.encode(text))

def split_into_chunks(text, max_tokens, encoding):
    lines = text.split('\n')
    chunks = []
    current_chunk = []
    current_tokens = 0

    for line in lines:
        line_with_newline = line + '\n'
        line_tokens = count_tokens(line_with_newline, encoding)

        if current_tokens + line_tokens > max_tokens and current_chunk:
            chunks.append(''.join(current_chunk).rstrip('\n'))
            current_chunk = [line_with_newline]
            current_tokens = line_tokens
        else:
            current_chunk.append(line_with_newline)
            current_tokens += line_tokens

    if current_chunk:
        chunks.append(''.join(current_chunk).rstrip('\n'))

    return chunks

def process_chunk(chunk, command, index):
    try:
        result = subprocess.run(
            command,
            input=chunk,
            capture_output=True,
            text=True,
            shell=True
        )
        return (index, result.stdout, result.stderr, result.returncode)
    except Exception as e:
        return (index, "", str(e), 1)

parser = argparse.ArgumentParser(description='Process input in token-based chunks')
parser.add_argument('-f', '--file', help='Input file (uses stdin if not provided)')
parser.add_argument('-t', '--tokens', type=int, required=True, help='Max tokens per chunk')
parser.add_argument('command', nargs=argparse.REMAINDER, help='Command to run on each chunk')

args = parser.parse_args()

if not args.command:
    print("Error: No command provided", file=sys.stderr)
    sys.exit(1)

command_str = ' '.join(args.command)

if args.file:
    with open(args.file, 'r') as f:
        input_text = f.read()
else:
    input_text = sys.stdin.read()

encoding = tiktoken.encoding_for_model('gpt-4')
chunks = split_into_chunks(input_text, args.tokens, encoding)

results = {}
with ThreadPoolExecutor() as executor:
    futures = {
        executor.submit(process_chunk, chunk, command_str, i): i
        for i, chunk in enumerate(chunks)
    }

    for future in as_completed(futures):
        index, stdout, stderr, returncode = future.result()
        results[index] = (stdout, stderr, returncode)

for i in range(len(chunks)):
    stdout, stderr, returncode = results[i]
    if stdout:
        print(stdout, end='')
    if stderr:
        print(stderr, file=sys.stderr, end='')
    if returncode != 0:
        sys.exit(returncode)
