#!/usr/bin/env -S uv run --script --quiet
"""Extract and manage browser cookies for specified domains."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "browser-cookie3>=0.20,<0.21",
#   "sh>=2.1,<3",
# ]
# ///


import argparse
import browser_cookie3
import sys
import sh
from collections import defaultdict

def get_cookies(domain, browser='chrome', cookie_file=None):
    try:
        if browser == 'chrome':
            cookies = browser_cookie3.chrome(domain_name=domain, cookie_file=cookie_file)
        elif browser == 'firefox':
            cookies = browser_cookie3.firefox(domain_name=domain)
        elif browser == 'safari':
            cookies = browser_cookie3.safari(domain_name=domain)
        else:
            print(f"Unsupported browser: {browser}", file=sys.stderr)
            sys.exit(1)

        return '; '.join(f'{c.name}={c.value}' for c in cookies)
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

def get_domains(browser='chrome', cookie_file=None):
    try:
        if browser == 'chrome':
            cookies = browser_cookie3.chrome(cookie_file=cookie_file)
        elif browser == 'firefox':
            cookies = browser_cookie3.firefox()
        elif browser == 'safari':
            cookies = browser_cookie3.safari()
        else:
            print(f"Unsupported browser: {browser}", file=sys.stderr)
            sys.exit(1)

        domains = defaultdict(int)
        for cookie in cookies:
            domains[cookie.domain] += 1

        # Sort domains by frequency (descending)
        sorted_domains = sorted(domains.items(), key=lambda x: (-x[1], x[0]))
        return [domain for domain, _ in sorted_domains]
    except Exception as e:
        print(f"Error listing domains: {str(e)}", file=sys.stderr)
        sys.exit(1)

def select_domain_with_fzf(domains):
    try:
        # Check if fzf is installed
        try:
            sh.which('fzf')
        except sh.ErrorReturnCode:
            print("Error: fzf is not installed. Please install it or specify a domain.", file=sys.stderr)
            sys.exit(1)

        # Create input for fzf
        domains_str = '\n'.join(domains)

        # Run fzf and capture output

        try:
            selected_domain = sh.fzf('--height', '40%', '--reverse', _in=domains_str).strip()
            return selected_domain
        except sh.ErrorReturnCode:
            print("Domain selection cancelled", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error during domain selection: {str(e)}", file=sys.stderr)
        sys.exit(1)

# Parse arguments
parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('domain', type=str, nargs='?', help="Domain to extract cookies for (optional, will use fzf if not provided)")
parser.add_argument('-b', '--browser', choices=['chrome', 'firefox', 'safari'], default='chrome',
                    help="Browser to extract cookies from")
parser.add_argument('-c', '--cookie-file', type=str, help="Path to the cookie file")
args = parser.parse_args()

domain = args.domain
if not domain:
    domains = get_domains(args.browser, args.cookie_file)
    if not domains:
        print("No domains found", file=sys.stderr)
        sys.exit(1)
    domain = select_domain_with_fzf(domains)

cookie_header = get_cookies(domain, args.browser, args.cookie_file)
print(cookie_header)