#!/usr/bin/env -S uv run --script --quiet
"""Convert markdown to HTML with embedded resources."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "joblib",
#   "platformdirs",
#   "sh",
# ]
# ///


import argparse
import hashlib
import os
import sys
import tempfile
from pathlib import Path
from platformdirs import user_cache_dir
from joblib import Memory
import sh

# Initialize persistent cache
cache_dir = user_cache_dir("2html")
memory = Memory(cache_dir, verbose=0)

@memory.cache
def convert_markdown_to_html(content, title):
    """Convert markdown to HTML with caching (yarn build only)"""
    result = sh.yarn('run', 'build:html', '--title', title, _in=content)
    return str(result)

@memory.cache
def process_full_html(content, title):
    """Convert markdown to HTML and process with single-file-cli"""
    # Get initial HTML from yarn build
    html_content = convert_markdown_to_html(content, title)

    # Create temp file for single-file processing
    with tempfile.NamedTemporaryFile(mode='w', suffix='.html', delete=False) as temp_file:
        temp_path = temp_file.name
        temp_file.write(html_content)

    temp_output = f"{temp_path}.singlefile.html"
    browser = os.environ.get('BROWSER')

    try:
        if browser:
            try:
                sh.bunx('single-file-cli',
                       f'--browser-executable-path={browser}',
                       f'file://{temp_path}',
                       temp_output)

                if Path(temp_output).exists() and Path(temp_output).stat().st_size > 0:
                    with open(temp_output) as f:
                        result = f.read()
                else:
                    result = html_content
            except sh.ErrorReturnCode:
                result = html_content
        else:
            result = html_content
    finally:
        # Clean up temp files
        if Path(temp_path).exists():
            os.unlink(temp_path)
        if Path(temp_output).exists():
            os.unlink(temp_output)

    return result

parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--title', default='Document', help='Title for the HTML document')
args = parser.parse_args()

script_dir = Path(__file__).parent
vite_dir = script_dir / '2html-vite'

if not vite_dir.exists():
    print(f"Error: {vite_dir} does not exist", file=sys.stderr)
    sys.exit(1)

os.chdir(vite_dir)

markdown_content = sys.stdin.read()

try:
    result = process_full_html(markdown_content, args.title)
    print(result)
except Exception as e:
    print(f"Error: {str(e)}", file=sys.stderr)
    sys.exit(1)