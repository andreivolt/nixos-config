#!/usr/bin/env python3
"""Extract cookies from curl commands and convert to JSON format."""
import sys
import re
import json
import argparse
from urllib.parse import urlparse

def extract_cookies_from_curl(curl_command, domain=None):
    """Extract cookies from curl command and convert to JSON format."""
    # Find Cookie header in curl command
    cookie_match = re.search(r"-H\s+['\"]Cookie:\s*([^'\"]+)['\"]", curl_command)
    if not cookie_match:
        return []

    cookie_string = cookie_match.group(1)

    # Extract domain from URL if not provided
    if not domain:
        url_match = re.search(r"curl\s+['\"]?([^\s'\"]+)", curl_command)
        if url_match:
            parsed_url = urlparse(url_match.group(1))
            domain = parsed_url.hostname

    # Parse cookies
    cookies = []
    for cookie in cookie_string.split(';'):
        cookie = cookie.strip()
        if '=' in cookie:
            name, value = cookie.split('=', 1)
            cookies.append({
                "name": name.strip(),
                "value": value.strip(),
                "domain": f".{domain}" if domain else "",
                "path": "/"
            })

    return cookies

# Parse arguments
parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d', '--domain', help='Domain for cookies (extracted from URL if not provided)')
parser.add_argument('-o', '--output', help='Output file')
parser.add_argument('input', nargs='?', help='Input file containing curl command')

args = parser.parse_args()

# Read input
if args.input:
    with open(args.input, 'r') as f:
        curl_command = f.read()
else:
    curl_command = sys.stdin.read()

# Extract cookies
cookies = extract_cookies_from_curl(curl_command, args.domain)

# Output

json_output = json.dumps(cookies, indent=2)
if args.output:
    with open(args.output, 'w') as f:
        f.write(json_output)
else:
    print(json_output)