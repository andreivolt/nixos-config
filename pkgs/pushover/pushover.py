#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["httpx"]
# ///
"""
Pushover notification script supporting all API features.

Usage:
    pushover "Your message"
    pushover -t "Title" "Message"
    pushover -p 1 -s siren "Emergency!" --retry 60 --expire 3600
    echo "Message" | pushover

Environment variables:
    PUSHOVER_TOKEN - Application API token
    PUSHOVER_USER  - User/Group key
"""

import argparse
import os
import sys
import httpx

API_URL = "https://api.pushover.net/1/messages.json"

def send_notification(
    message: str,
    title: str | None = None,
    priority: int = 0,
    sound: str | None = None,
    device: str | None = None,
    url: str | None = None,
    url_title: str | None = None,
    html: bool = False,
    monospace: bool = False,
    timestamp: int | None = None,
    retry: int | None = None,
    expire: int | None = None,
    callback: str | None = None,
    attachment: str | None = None,
) -> dict:
    token = os.environ.get("PUSHOVER_TOKEN") or os.environ.get("pushover_token")
    user = os.environ.get("PUSHOVER_USER") or os.environ.get("pushover_user")

    if not token or not user:
        raise ValueError("PUSHOVER_TOKEN and PUSHOVER_USER environment variables required")

    data = {
        "token": token,
        "user": user,
        "message": message,
    }

    if title:
        data["title"] = title
    if priority != 0:
        data["priority"] = priority
    if sound:
        data["sound"] = sound
    if device:
        data["device"] = device
    if url:
        data["url"] = url
    if url_title:
        data["url_title"] = url_title
    if html:
        data["html"] = 1
    if monospace:
        data["monospace"] = 1
    if timestamp:
        data["timestamp"] = timestamp

    # Emergency priority (2) requires retry and expire
    if priority == 2:
        data["retry"] = retry or 60
        data["expire"] = expire or 3600
        if callback:
            data["callback"] = callback

    files = None
    if attachment and os.path.exists(attachment):
        files = {"attachment": open(attachment, "rb")}

    try:
        response = httpx.post(API_URL, data=data, files=files, timeout=30)
        response.raise_for_status()
        return response.json()
    finally:
        if files:
            files["attachment"].close()


def main():
    parser = argparse.ArgumentParser(description="Send Pushover notifications")
    parser.add_argument("message", nargs="?", help="Message to send (or pipe via stdin)")
    parser.add_argument("-t", "--title", help="Message title")
    parser.add_argument("-p", "--priority", type=int, default=0, choices=[-2, -1, 0, 1, 2],
                        help="Priority: -2=lowest, -1=low, 0=normal, 1=high, 2=emergency")
    parser.add_argument("-s", "--sound", help="Sound name (pushover, bike, bugle, etc.)")
    parser.add_argument("-d", "--device", help="Target specific device")
    parser.add_argument("-u", "--url", help="Supplementary URL")
    parser.add_argument("--url-title", help="Title for supplementary URL")
    parser.add_argument("--html", action="store_true", help="Enable HTML formatting")
    parser.add_argument("--monospace", action="store_true", help="Use monospace font")
    parser.add_argument("--timestamp", type=int, help="Unix timestamp")
    parser.add_argument("--retry", type=int, help="Retry interval for emergency (seconds)")
    parser.add_argument("--expire", type=int, help="Expiration for emergency (seconds)")
    parser.add_argument("--callback", help="Callback URL for emergency acknowledgment")
    parser.add_argument("-a", "--attachment", help="Image file to attach")

    args = parser.parse_args()

    # Get message from argument or stdin
    message = args.message
    if not message and not sys.stdin.isatty():
        message = sys.stdin.read().strip()

    if not message:
        parser.error("Message required (as argument or via stdin)")

    try:
        result = send_notification(
            message=message,
            title=args.title,
            priority=args.priority,
            sound=args.sound,
            device=args.device,
            url=args.url,
            url_title=args.url_title,
            html=args.html,
            monospace=args.monospace,
            timestamp=args.timestamp,
            retry=args.retry,
            expire=args.expire,
            callback=args.callback,
            attachment=args.attachment,
        )
        print(f"Sent: {result.get('status', 'ok')}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
