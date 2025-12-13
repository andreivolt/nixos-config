#!/usr/bin/env -S uv run --script --quiet
"""Access and manage Gmail messages via Google API."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "dominate",
#   "google-api-python-client",
#   "google-auth",
#   "google-auth-httplib2",
#   "google-auth-oauthlib",
#   "html2text",
#   "platformdirs",
#   "pyperclip",
#   "sh",
# ]
# ///


import os
import base64
import argparse
import pyperclip
from sh import Command, ErrorReturnCode
import re
import sys
import time
import webbrowser
import tempfile
import json
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
import pickle
import html2text
import dominate
from dominate.tags import *
from dominate.util import text, raw
from platformdirs import user_cache_dir, user_config_dir
from pathlib import Path

SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]
TOKEN_FILE = user_cache_dir("gmail") + "/gmail-token.pickle"
CREDENTIALS_FILE = user_config_dir("gmail") + "/gmail-credentials.json"


def get_gmail_service():
    creds = None

    # Ensure cache directory exists
    os.makedirs(os.path.dirname(TOKEN_FILE), exist_ok=True)

    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, "rb") as token:
            creds = pickle.load(token)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except Exception:
                # If refresh fails, delete token and force new OAuth flow
                if os.path.exists(TOKEN_FILE):
                    os.remove(TOKEN_FILE)
                creds = None

        if not creds:  # Need new credentials (either never had them or refresh failed)
            # Ensure config directory exists
            os.makedirs(os.path.dirname(CREDENTIALS_FILE), exist_ok=True)

            if not os.path.exists(CREDENTIALS_FILE):
                print(f"Please download OAuth2 credentials from Google Cloud Console")
                print(f"and save to: {CREDENTIALS_FILE}")
                exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0, bind_addr='127.0.0.1')

        with open(TOKEN_FILE, "wb") as token:
            pickle.dump(creds, token)

    # Use cache_discovery=False to avoid hanging issues with discovery document caching
    # This is a known issue with google-api-python-client v1.x
    service = build("gmail", "v1", credentials=creds, cache_discovery=False)
    return service


def get_message_parts(payload):
    text_part = None
    html_part = None
    attachments = []

    if "parts" in payload:
        for part in payload["parts"]:
            if part["mimeType"] == "text/plain" and not text_part:
                text_part = part
            elif part["mimeType"] == "text/html" and not html_part:
                html_part = part
            elif "filename" in part and part["filename"]:
                # This is an attachment
                attachments.append(part)
            elif "parts" in part:
                sub_text, sub_html, sub_attachments = get_message_parts(part)
                if sub_text and not text_part:
                    text_part = sub_text
                if sub_html and not html_part:
                    html_part = sub_html
                attachments.extend(sub_attachments)
    else:
        if payload["mimeType"] == "text/plain":
            text_part = payload
        elif payload["mimeType"] == "text/html":
            html_part = payload

    return text_part, html_part, attachments


def decode_part(part):
    if part and "data" in part.get("body", {}):
        return base64.urlsafe_b64decode(part["body"]["data"]).decode("utf-8")
    return ""


def process_attachment_to_text(attachment_data, filename, mime_type):
    """Convert attachment to text using 2text tool"""
    try:
        # Create a temporary file to save the attachment
        with tempfile.NamedTemporaryFile(delete=False, suffix=Path(filename).suffix) as tmp_file:
            tmp_file.write(attachment_data)
            tmp_path = tmp_file.name
        
        # Use 2text to convert the file
        try:
            two_text = Command("2text")
            result = two_text(tmp_path).stdout.decode("utf-8")
            return result
        except (ErrorReturnCode, FileNotFoundError):
            # If 2text fails or is not available, return basic info
            return f"[Attachment: {filename} ({mime_type}) - {len(attachment_data):,} bytes]"
        finally:
            # Clean up temporary file
            os.unlink(tmp_path)
    except Exception as e:
        return f"[Error processing attachment {filename}: {str(e)}]"


def format_as_markdown(msg, service=None, include_attachments=True):
    payload = msg["payload"]
    headers = payload.get("headers", [])

    header_dict = {h["name"]: h["value"] for h in headers}

    markdown = f"# {header_dict.get('Subject', 'No Subject')}\n\n"
    markdown += f"**From:** {header_dict.get('From', 'Unknown')}\n\n"
    markdown += f"**To:** {header_dict.get('To', 'Unknown')}\n\n"
    markdown += f"**Date:** {header_dict.get('Date', 'Unknown')}\n\n"
    markdown += "---\n\n"

    text_part, html_part, attachments = get_message_parts(payload)

    if html_part:
        html_content = decode_part(html_part)
        h = html2text.HTML2Text()
        h.ignore_links = False
        markdown += h.handle(html_content)
    elif text_part:
        text_content = decode_part(text_part)
        markdown += text_content
    else:
        markdown += "*No content found*"

    # Process attachments if present
    if attachments and include_attachments:
        markdown += "\n\n---\n\n## Attachments\n\n"
        
        for attachment in attachments:
            filename = attachment.get("filename", "Unnamed")
            mime_type = attachment.get("mimeType", "unknown")
            attachment_id = attachment["body"].get("attachmentId")
            
            markdown += f"### {filename}\n\n"
            
            if service and attachment_id:
                try:
                    # Fetch the attachment data
                    att_data = service.users().messages().attachments().get(
                        userId="me", 
                        messageId=msg["id"],
                        id=attachment_id
                    ).execute()
                    
                    # Decode attachment data
                    file_data = base64.urlsafe_b64decode(att_data["data"])
                    
                    # Convert to text using 2text
                    text_content = process_attachment_to_text(file_data, filename, mime_type)
                    markdown += f"```\n{text_content}\n```\n\n"
                except Exception as e:
                    markdown += f"*Error loading attachment: {str(e)}*\n\n"
            else:
                markdown += f"*Attachment: {filename} ({mime_type})*\n\n"

    return markdown


def format_as_html(msg):
    payload = msg["payload"]
    headers = payload.get("headers", [])

    header_dict = {h["name"]: h["value"] for h in headers}

    doc = dominate.document(title=header_dict.get("Subject", "Email"))

    with doc.head:
        meta(charset="utf-8")
        style(
            """
            body { font-family: Arial, sans-serif; margin: 20px; }
            .headers { background: #f0f0f0; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
            .header-item { margin: 5px 0; }
            .content { padding: 15px; }
        """
        )

    with doc:
        with div(cls="headers"):
            h2(header_dict.get("Subject", "No Subject"))
            with div(cls="header-item"):
                strong("From:")
                text(" " + header_dict.get("From", "Unknown"))
            with div(cls="header-item"):
                strong("To:")
                text(" " + header_dict.get("To", "Unknown"))
            with div(cls="header-item"):
                strong("Date:")
                text(" " + header_dict.get("Date", "Unknown"))

        with div(cls="content"):
            text_part, html_part, attachments = get_message_parts(payload)

            if html_part:
                # Insert raw HTML content
                raw(decode_part(html_part))
            elif text_part:
                pre(decode_part(text_part))
            else:
                with p():
                    em("No content found")

    return str(doc)


def format_as_json(msg, service=None, include_attachments=True):
    payload = msg["payload"]
    headers = payload.get("headers", [])
    header_dict = {h["name"]: h["value"] for h in headers}

    text_part, html_part, attachments = get_message_parts(payload)

    result = {
        "id": msg["id"],
        "threadId": msg["threadId"],
        "subject": header_dict.get("Subject", ""),
        "from": header_dict.get("From", ""),
        "to": header_dict.get("To", ""),
        "date": header_dict.get("Date", ""),
        "snippet": msg.get("snippet", ""),
        "body": {
            "text": decode_part(text_part) if text_part else "",
            "html": decode_part(html_part) if html_part else "",
        },
    }

    if attachments and include_attachments:
        result["attachments"] = []
        for attachment in attachments:
            att_info = {
                "filename": attachment.get("filename", "Unnamed"),
                "mimeType": attachment.get("mimeType", "unknown"),
                "size": attachment["body"].get("size", 0)
            }
            
            attachment_id = attachment["body"].get("attachmentId")
            if service and attachment_id:
                try:
                    # Fetch the attachment data
                    att_data = service.users().messages().attachments().get(
                        userId="me", 
                        messageId=msg["id"],
                        id=attachment_id
                    ).execute()
                    
                    # Decode attachment data
                    file_data = base64.urlsafe_b64decode(att_data["data"])
                    
                    # Convert to text using 2text
                    att_info["text_content"] = process_attachment_to_text(
                        file_data, att_info["filename"], att_info["mimeType"]
                    )
                except Exception as e:
                    att_info["error"] = str(e)
            
            result["attachments"].append(att_info)

    return json.dumps(result, indent=2)


def output_message(msg, args, service=None):
    if args.browser:
        html_content = format_as_html(msg)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html_content)
            f.flush()
            webbrowser.open(f"file://{f.name}")
    elif args.json:
        print(format_as_json(msg, service=service))
    elif args.html:
        print(format_as_html(msg))
    else:
        markdown_content = format_as_markdown(msg, service=service)
        try:
            glow = Command("glow")
            print(glow(_in=markdown_content))
        except (ErrorReturnCode, FileNotFoundError):
            print(markdown_content)


def cmd_last(service, args):
    # Build query to exclude sent emails
    query = "-from:me"
    
    # Add sender filter if specified
    if args.sender:
        query += f" from:{args.sender}"
    
    # Get last received email matching criteria
    results = service.users().messages().list(userId="me", q=query, maxResults=1).execute()
    messages = results.get("messages", [])

    if not messages:
        if args.sender:
            print(f"No messages found from sender: {args.sender}")
        else:
            print("No messages found.")
        return

    msg = service.users().messages().get(userId="me", id=messages[0]["id"]).execute()
    output_message(msg, args, service=service)


def extract_verification_info(subject, body_text, body_html):
    # Common verification code patterns
    code_patterns = [
        r'\b\d{6}\b',
        r'\b\d{4,8}\b',
        r'\b[A-Z0-9]{6,8}\b',
        r'(?:code|verification|OTP|passcode)[\s:]+([A-Z0-9]{4,8})',
        r'(?:Your|The|Use)[\s\w]*(?:code|verification|OTP)[\s\w]*:?\s*([A-Z0-9]{4,8})',
    ]

    # URL patterns for verification links
    url_patterns = [
        r'https?://[^\s<>"{}|\\^`\[\]]+(?:verify|confirm|activate|validate)[^\s<>"{}|\\^`\[\]]*',
        r'https?://[^\s<>"{}|\\^`\[\]]+',
    ]

    # Extract from plain text first, fall back to HTML
    content = body_text or ""
    if not content and body_html:
        h = html2text.HTML2Text()
        h.ignore_links = False
        content = h.handle(body_html)

    codes = []
    urls = []

    # Look for codes
    for pattern in code_patterns:
        matches = re.findall(pattern, content, re.IGNORECASE)
        codes.extend(matches)

    # Look for URLs
    for pattern in url_patterns:
        matches = re.findall(pattern, content)
        urls.extend(matches)

    # Deduplicate while preserving order
    codes = list(dict.fromkeys(codes))
    urls = list(dict.fromkeys(urls))

    return codes[:3], urls[:3]  # Return top 3 of each


def matches_prompt(subject, from_addr, body_text, prompt):
    """Check if email matches the user's prompt using simple keyword matching"""
    prompt_lower = prompt.lower()
    subject_lower = subject.lower()
    from_lower = from_addr.lower()
    body_lower = (body_text or "").lower()[:500]  # Check first 500 chars of body

    # Split prompt into keywords
    keywords = prompt_lower.split()

    # Check if any keyword matches
    for keyword in keywords:
        if keyword in subject_lower or keyword in from_lower or keyword in body_lower:
            return True

    # Also check for verification-related terms if the prompt seems to be about verification
    verification_terms = ['verification', 'verify', 'code', 'otp', '2fa', 'confirm', 'login', 'signin']
    if any(term in prompt_lower for term in verification_terms):
        return is_verification_email(subject, from_addr)

    return False


def is_verification_email(subject, from_addr):
    verification_keywords = [
        'verification', 'verify', 'confirm', 'code', 'otp', 'authentication',
        'two-factor', '2fa', 'signin', 'sign in', 'login', 'passcode',
        'activate', 'validate', 'security code'
    ]

    subject_lower = subject.lower()
    return any(keyword in subject_lower for keyword in verification_keywords)


def copy_to_clipboard(text):
    pyperclip.copy(text)


def notify_hammerspoon(title, message, sticky=True):
    script = f'''
    hs.notify.new({{
        title = "{title}",
        informativeText = "{message}",
        withdrawAfter = {0 if sticky else 5}
    }}):send()
    '''
    hs = Command("hs")
    hs('-c', script)


def notify_terminal(title, message):
    terminal_notifier = Command("terminal-notifier")
    terminal_notifier('-title', title, '-message', message)


def process_verification_email(msg):
    payload = msg["payload"]
    headers = payload.get("headers", [])
    header_dict = {h["name"]: h["value"] for h in headers}

    subject = header_dict.get("Subject", "")
    from_addr = header_dict.get("From", "")

    text_part, html_part, attachments = get_message_parts(payload)
    body_text = decode_part(text_part) if text_part else ""
    body_html = decode_part(html_part) if html_part else ""

    codes, urls = extract_verification_info(subject, body_text, body_html)

    handled = False

    # Handle codes
    if codes:
        code = codes[0]  # Use the first/most likely code
        copy_to_clipboard(code)

        title = "Verification Code"
        message = f"Code {code} copied to clipboard\nFrom: {from_addr}"

        notify_hammerspoon(title, message, sticky=True)
        notify_terminal(title, message)

        print(f"✓ Code copied: {code}")
        handled = True

    # Handle verification links
    if urls:
        verification_urls = [u for u in urls if any(kw in u.lower() for kw in ['verify', 'confirm', 'activate', 'validate'])]
        url = verification_urls[0] if verification_urls else urls[0]

        webbrowser.open(url)

        title = "Verification Link"
        message = f"Opening verification link\nFrom: {from_addr}"

        notify_hammerspoon(title, message, sticky=False)
        notify_terminal(title, message)

        print(f"✓ Opened URL: {url}")
        handled = True

    if not handled:
        print(f"⚠ No verification code or link found in: {subject}")

    return handled


def cmd_monitor(service, args):
    prompt = " ".join(args.prompt) if args.prompt else "verification code"
    
    # Build base query
    query = "-from:me is:unread"
    
    # Add sender filter if specified
    if args.sender:
        query += f" from:{args.sender}"
        print(f"Monitoring emails matching: '{prompt}' from sender: {args.sender}")
    else:
        print(f"Monitoring emails matching: '{prompt}'")

    # Get current latest message ID to avoid processing old emails
    results = service.users().messages().list(userId="me", q=query, maxResults=1).execute()
    messages = results.get("messages", [])
    processed_ids = set()

    if messages:
        for msg_ref in messages:
            processed_ids.add(msg_ref["id"])

    while True:
        try:
            # Check for new unread received messages
            results = service.users().messages().list(userId="me", q=query, maxResults=10).execute()
            messages = results.get("messages", [])

            for msg_ref in messages:
                if msg_ref["id"] not in processed_ids:
                    # New message found
                    msg = service.users().messages().get(userId="me", id=msg_ref["id"]).execute()

                    payload = msg["payload"]
                    headers = payload.get("headers", [])
                    header_dict = {h["name"]: h["value"] for h in headers}

                    subject = header_dict.get("Subject", "")
                    from_addr = header_dict.get("From", "")

                    text_part, html_part, attachments = get_message_parts(payload)
                    body_text = decode_part(text_part) if text_part else ""

                    # Check if email matches the prompt
                    if matches_prompt(subject, from_addr, body_text, prompt):
                        print(f"\n📧 New email matching prompt: {subject}")
                        if process_verification_email(msg):
                            # Mark as read if successfully processed
                            if args.mark_read:
                                service.users().messages().modify(
                                    userId="me",
                                    id=msg_ref["id"],
                                    body={"removeLabelIds": ["UNREAD"]}
                                ).execute()

                    processed_ids.add(msg_ref["id"])

            time.sleep(args.interval)

        except KeyboardInterrupt:
            print("\nStopping monitor...")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(args.interval)


parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("--html", action="store_true", help="Output as HTML")
parser.add_argument("--json", action="store_true", help="Output as JSON")
parser.add_argument(
    "--browser", action="store_true", help="Open in browser (implies --html)"
)
parser.add_argument("--sender", type=str, help="Filter emails by sender address")

subparsers = parser.add_subparsers(dest="command", help="Commands")

# last command (default)
last_parser = subparsers.add_parser("last", help="Show last received message (default)")

# monitor command
monitor_parser = subparsers.add_parser("monitor", help="Monitor for emails matching a prompt")
monitor_parser.add_argument("prompt", nargs="*", help="Keywords to match in emails")
monitor_parser.add_argument("--interval", type=int, default=5, help="Check interval in seconds")
monitor_parser.add_argument("--mark-read", action="store_true", help="Mark processed emails as read")

args = parser.parse_args()

# Default to 'last' command if no command specified

if not args.command:
    args.command = "last"

service = get_gmail_service()

if args.command == "last":
    cmd_last(service, args)
elif args.command == "monitor":
    cmd_monitor(service, args)