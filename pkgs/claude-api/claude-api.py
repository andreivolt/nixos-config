#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "tzlocal",
#   "curl_cffi",
#   "browser_cookie3",
#   "pysocks",
#   "joblib",
#   "parsedatetime",
#   "tabulate",
#   "platformdirs",
#   "click"
# ]
# ///

import os
import sys
import tempfile
import json
import webbrowser
import click
from os import path as ospath
from json import dumps, loads
from uuid import uuid4
from collections import namedtuple
from mimetypes import guess_type
from zlib import decompress as zlib_decompress
from zlib import MAX_WBITS
from tzlocal import get_localzone
from typing import List, Dict
from builtins import list as builtin_list
from curl_cffi.requests import get as http_get
from curl_cffi.requests import post as http_post
from curl_cffi.requests import delete as http_delete
from curl_cffi.requests import put as http_put
from datetime import datetime
import browser_cookie3
from joblib import Memory
from tabulate import tabulate
from platformdirs import user_cache_dir, user_state_dir


# ============================================================================
# Constants
# ============================================================================

BASE_URL = "https://claude.ai"
DEFAULT_TIMEOUT = 240
DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
FILE_SIZE_LIMIT = 10485760  # 10 MB
MAX_ATTACHMENTS = 5

# Model mappings
MODEL_ALIASES = {
    'opus': 'claude-opus-4-20250514',
    'sonnet': 'claude-sonnet-4-20250514'
}

# Default tools configuration
DEFAULT_TOOLS = [
    {"type": "web_search_v0", "name": "web_search"},
    {"type": "artifacts_v0", "name": "artifacts"},
    {"type": "repl_v0", "name": "repl"}
]

# Default personalized styles
DEFAULT_STYLES = [{
    "type": "default",
    "key": "Default",
    "name": "Normal",
    "nameKey": "normal_style_name",
    "prompt": "Normal",
    "summary": "Default responses from Claude",
    "summaryKey": "normal_style_summary",
    "isDefault": True
}]


# ============================================================================
# Utility Functions
# ============================================================================

def handle_api_error(response, context: str = "API request"):
    """Centralized API error handling"""
    if response.status_code == 200:
        return

    error_msg = f"{context} failed with status {response.status_code}"
    try:
        error_data = response.json()
        if "error" in error_data:
            error_msg += f": {error_data['error'].get('message', 'Unknown error')}"
    except:
        error_msg += f": {response.text}"

    raise ClaudeAPIError(error_msg)

def safe_date_parse(date_str: str, context: str = "date") -> datetime | None:
    """Safely parse dates with error handling"""
    if not date_str:
        return None
    try:
        return datetime.fromisoformat(date_str.replace('Z', '+00:00')).replace(tzinfo=None)
    except (ValueError, TypeError):
        print(f"Warning: Could not parse {context}: {date_str}", file=sys.stderr)
        return None

def create_temp_attachment(content: str) -> str:
    """Create a temporary file for attachment and return its path"""
    # Use NamedTemporaryFile with delete=False so we can use the path
    # but manually clean it up in the finally block
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False, encoding='utf-8') as tmp_file:
        tmp_file.write(content)
        return tmp_file.name


# ============================================================================
# Exception Classes
# ============================================================================

class ClaudeAPIError(Exception):
    """Base error class for all Claude API errors"""
    pass


class MessageRateLimitError(ClaudeAPIError):
    """Raised when the user hits the message limit rate"""
    def __init__(self, reset_timestamp: int) -> None:
        self.reset_timestamp: int = reset_timestamp
        self.reset_date: datetime = datetime.fromtimestamp(reset_timestamp)


    def __str__(self) -> str:
        return f"Message limit hit, reset at {self.reset_date}"


class OverloadError(ClaudeAPIError):
    """Raised when the user hits the overload error"""
    pass


# ============================================================================
# Data Classes
# ============================================================================

# Session data structure
SessionData = namedtuple('SessionData', ['cookie', 'user_agent', 'organization_id'])


# Response structure for send_message
SendMessageResponse = namedtuple('SendMessageResponse', ['answer', 'status_code', 'raw_answer', 'model'])


# ============================================================================
# Session Management
# ============================================================================

def get_claude_session() -> SessionData:
    """Get Claude session from Chrome browser cookies"""
    cj = browser_cookie3.chrome(domain_name='claude.ai')
    cookie_dict = {}

    for cookie in cj:
        if cookie.domain == '.claude.ai' or cookie.domain == 'claude.ai':
            cookie_dict[cookie.name] = cookie.value

    if not cookie_dict:
        raise RuntimeError("Could not retrieve Claude cookies from Chrome")

    # Build cookie header string
    cookie_header = '; '.join([f"{name}={value}" for name, value in cookie_dict.items()])

    user_agent = DEFAULT_USER_AGENT

    return SessionData(cookie_header, user_agent, None)


# ============================================================================
# Claude API Client
# ============================================================================

class ClaudeAPIClient:
    """Claude API client with all functionality"""

    def __init__(self, session: SessionData, model_name: str = None, timeout: float = DEFAULT_TIMEOUT):
        self.model_name = model_name
        self.timeout = timeout
        self.session = session
        self.timezone = get_localzone().key

        # Initialize cache
        cache_dir = user_cache_dir('claude-api')
        self.memory = Memory(cache_dir, verbose=0)

        # Store reference to cached function for invalidation
        self._cached_fetch_conversations = None

        # Get organization ID if not provided
        self.organization_id = session.organization_id or self._get_organization_id()

    def get_headers(self, request_type: str = "api", extra: dict = None, **kwargs) -> dict:
        """Get headers for requests with flexible customization

        Args:
            request_type: "api", "navigation", or "base"
            extra: Additional headers to include
            **kwargs: Common header overrides (referer, content_type, content_length, accept)
        """
        # Base headers common to all requests
        headers = {
            "Host": "claude.ai",
            "User-Agent": self.session.user_agent,
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "DNT": "1",
            "Connection": "keep-alive",
            "Cookie": self.session.cookie,
        }

        # Add type-specific headers
        if request_type == "api":
            headers.update({
                "Accept": "*/*",
                "Origin": BASE_URL,
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
                "TE": "trailers",
            })
        elif request_type == "navigation":
            headers.update({
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "none",
                "Sec-Fetch-User": "?1",
                "Upgrade-Insecure-Requests": "1",
            })
        # request_type == "base" uses only the base headers

        # Handle common kwargs
        if kwargs.get("referer"):
            headers["Referer"] = kwargs["referer"]
        if kwargs.get("content_type"):
            headers["Content-Type"] = kwargs["content_type"]
        if kwargs.get("content_length") is not None:
            headers["Content-Length"] = str(kwargs["content_length"])
        if kwargs.get("accept"):
            headers["Accept"] = kwargs["accept"]

        # Apply any extra headers
        if extra:
            headers.update(extra)

        return headers

    def _get_organization_id(self) -> str:
        """Retrieve organization ID from Claude API"""
        url = f"{BASE_URL}/api/organizations"
        headers = self.get_headers("navigation")

        response = http_get(url, headers=headers, timeout=self.timeout, impersonate="chrome110")

        if response.status_code == 200 and response.content:
            data = response.json()
            if data and "uuid" in data[0]:
                return data[0]["uuid"]

        raise RuntimeError(f"Cannot retrieve Organization ID!\n{response.text}")

    def _prepare_file_attachment(self, file_path: str, chat_id: str) -> dict | str | None:
        """Prepare file attachment for message"""
        content_type = self._get_content_type(file_path)

        if content_type == "text/plain":
            return self._prepare_text_attachment(file_path)

        return self._upload_file_attachment(file_path, chat_id)

    def _get_content_type(self, file_path: str) -> str:
        """Get MIME type for file"""
        extension = ospath.splitext(file_path)[1].lower()
        mime_type, _ = guess_type(f"file.{extension}")
        return mime_type or "application/octet-stream"

    def _prepare_text_attachment(self, file_path: str) -> dict:
        """Prepare text file as inline attachment"""
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        return {
            "extracted_content": content,
            "file_name": ospath.basename(file_path),
            "file_size": str(ospath.getsize(file_path)),
            "file_type": "text/plain",
        }

    def _upload_file_attachment(self, file_path: str, chat_id: str) -> str | None:
        """Upload binary file attachment"""
        url = f"{BASE_URL}/api/{self.organization_id}/upload"
        headers = self.get_headers("api", referer=f"{BASE_URL}/chat/{chat_id}")

        with open(file_path, "rb") as fp:
            files = {
                "file": (ospath.basename(file_path), fp, self._get_content_type(file_path)),
                "orgUuid": (None, self.organization_id),
            }

            response = http_post(url, headers=headers, files=files, timeout=self.timeout, impersonate="chrome110")

            if response.status_code == 200:
                data = response.json()
                if "file_uuid" in data:
                    return data["file_uuid"]

        print(f"[{response.status_code}] Unable to upload file -> {file_path}\n{response.text}")
        return None

    def _validate_attachments(self, attachment_paths: List[str]):
        """Validate attachment file paths and sizes"""
        if not attachment_paths:
            return

        if len(attachment_paths) > MAX_ATTACHMENTS:
            raise ValueError(f"Cannot attach more than {MAX_ATTACHMENTS} files!")

        for path in attachment_paths:
            if not ospath.exists(path) or not ospath.isfile(path):
                raise ValueError(f"Attachment file does not exist -> {path}")

            size = ospath.getsize(path)
            if size > FILE_SIZE_LIMIT:
                raise ValueError(f"File too large (>{size-FILE_SIZE_LIMIT} bytes over {FILE_SIZE_LIMIT//1024//1024}MB limit) -> {path}")

    def _decode_response(self, data: bytes, encoding: str) -> bytes:
        """Decode HTTP response based on encoding"""
        try:
            if encoding == "gzip":
                return zlib_decompress(data, MAX_WBITS | 16)
            elif encoding == "deflate":
                return zlib_decompress(data, -MAX_WBITS)
            # Brotli support removed as per original code
        except Exception:
            pass
        return data

    def _parse_message_response(self, data: bytes) -> tuple[str | None, str | None]:
        """Parse Claude's server-sent events response format, return (answer, model)"""
        text = data.decode("utf-8").strip()

        completions = []
        model_info = None

        # Parse server-sent events format
        for line in text.splitlines():
            if line.startswith("data: "):
                json_data = line[6:]  # Remove "data: " prefix
                try:
                    data_dict = loads(json_data)
                except json.JSONDecodeError:
                    continue

                if "error" in data_dict:
                    self._handle_error_response(data_dict["error"])

                # Extract model from message_start event
                if data_dict.get("type") == "message_start":
                    message = data_dict.get("message", {})
                    if "model" in message and message["model"]:
                        model_info = message["model"]

                # Extract text content from content_block_delta events
                if data_dict.get("type") == "content_block_delta":
                    delta = data_dict.get("delta", {})
                    if delta.get("type") == "text_delta":
                        completions.append(delta.get("text", ""))

        answer = "".join(completions).strip() if completions else None
        return answer, model_info

    def _parse_streaming_line(self, line: str) -> tuple[str | None, dict]:
        """Parse a single line from streaming response, return (completion, full_data)"""
        if not line.startswith("data: "):
            return None, {}

        json_data = line[6:]  # Remove "data: " prefix
        try:
            data_dict = loads(json_data)
        except json.JSONDecodeError:
            return None, {}

        if "error" in data_dict:
            self._handle_error_response(data_dict["error"])

        completion = None
        if data_dict.get("type") == "content_block_delta":
            delta = data_dict.get("delta", {})
            if delta.get("type") == "text_delta":
                completion = delta.get("text", "")

        return completion, data_dict

    def _handle_error_response(self, error_data: dict):
        """Handle error responses from Claude API"""
        error_message = error_data.get("message", "")
        error_type = error_data.get("type", "")

        # Check for rate limit error
        try:
            error_details = loads(error_message)
            if "resetsAt" in error_details:
                raise MessageRateLimitError(int(error_details["resetsAt"]))
        except (ValueError, TypeError):
            pass

        # Handle specific error types
        if "overloaded" in error_type:
            raise OverloadError(f"Claude is overloaded ({error_message})")

        # Generic API error
        raise ClaudeAPIError(f"Claude API error ({error_type}): {error_message}")

    # Public API methods
    def create_chat(self) -> str | None:
        """Create a new chat conversation"""
        url = f"{BASE_URL}/api/organizations/{self.organization_id}/chat_conversations"

        chat_uuid = str(uuid4())
        payload = {"name": "", "uuid": chat_uuid}

        payload_json = dumps(payload, separators=(",", ":"))

        headers = self.get_headers("api",
            referer=f"{BASE_URL}/chats",
            content_type="application/json",
            content_length=len(payload_json)
        )

        response = http_post(url, headers=headers, data=payload_json, timeout=self.timeout, impersonate="chrome110")

        if response.status_code == 201:
            data = response.json()
            if "uuid" in data:
                return data["uuid"]
        return None

    def delete_chat(self, chat_id: str) -> bool:
        """Delete a chat conversation"""
        url = f"{BASE_URL}/api/organizations/{self.organization_id}/chat_conversations/{chat_id}"

        headers = self.get_headers("api",
            referer=f"{BASE_URL}/chat/{chat_id}",
            content_type="application/json"
        )

        response = http_delete(url, headers=headers, data=f'"{chat_id}"', timeout=self.timeout, impersonate="chrome110")

        success = response.status_code == 204

        # Note: Cache invalidation is handled by caller to allow batch operations
        return success

    def remove_conversations_from_cache(self, chat_ids: List[str]):
        """Remove conversations from cache by invalidating it"""
        if chat_ids:
            # Simple and reliable: just clear the cache
            # The next call to get_all_conversations() will refresh it
            self.invalidate_conversations_cache()

    def invalidate_conversations_cache(self):
        """Clear the conversations cache"""
        if self._cached_fetch_conversations is not None:
            self._cached_fetch_conversations.clear(self.organization_id)


    def get_all_conversations(self, use_cache: bool = True) -> List[Dict]:
        """Get all chat conversations with metadata"""
        # Use caching to avoid slow API calls
        if self._cached_fetch_conversations is None:
            @self.memory.cache
            def _fetch_conversations(org_id: str) -> List[Dict]:
                url = f"{BASE_URL}/api/organizations/{org_id}/chat_conversations"
                headers = self.get_headers("navigation")

                response = http_get(url, headers=headers, timeout=self.timeout, impersonate="chrome110")

                if response.status_code == 200:
                    data = response.json()
                    # Check if data is paginated (has 'data' key) or direct array
                    if isinstance(data, dict) and "data" in data:
                        # Paginated response
                        conversations_data = data["data"]
                        # TODO: Handle pagination if needed (check for 'next_page' or similar)
                    elif isinstance(data, builtin_list):
                        # Direct array response
                        conversations_data = data
                    else:
                        return []

                    conversations = []
                    for chat in conversations_data:
                        if "uuid" in chat:
                            conversations.append({
                                "uuid": chat["uuid"],
                                "name": chat.get("name", ""),
                                "summary": chat.get("summary", ""),
                                "created_at": chat.get("created_at", ""),
                                "updated_at": chat.get("updated_at", ""),
                                "is_starred": chat.get("is_starred", False),
                                "paprika_mode": chat.get("settings", {}).get("paprika_mode")
                            })
                    return conversations
                return []

            self._cached_fetch_conversations = _fetch_conversations

        if use_cache:
            return self._cached_fetch_conversations(self.organization_id)
        else:
            # Clear cache and fetch fresh
            if self._cached_fetch_conversations is not None:
                self._cached_fetch_conversations.clear(self.organization_id)
            return self._cached_fetch_conversations(self.organization_id)

    def get_chat_data(self, chat_id: str) -> dict:
        """Get detailed data for a chat conversation"""
        url = f"{BASE_URL}/api/organizations/{self.organization_id}/chat_conversations/{chat_id}"

        headers = self.get_headers("navigation")

        response = http_get(url, headers=headers, timeout=self.timeout, impersonate="chrome110")
        return response.json()

    def _get_last_message_uuid(self, chat_id: str) -> str:
        """Get the UUID of the last message in a conversation for proper continuation"""
        try:
            # Use a shorter timeout for this call to avoid hanging
            url = f"{BASE_URL}/api/organizations/{self.organization_id}/chat_conversations/{chat_id}"
            headers = self.get_headers("navigation")

            # Make the request with a short timeout to prevent hanging
            response = http_get(url, headers=headers, timeout=10, impersonate="chrome110")

            if response.status_code == 200:
                chat_data = response.json()

                if "chat_messages" in chat_data and chat_data["chat_messages"]:
                    # Get the last message (should be from assistant)
                    last_message = chat_data["chat_messages"][-1]
                    if "uuid" in last_message:
                        return last_message["uuid"]
        except Exception:
            # If we can't get the last message, fall back to zero UUID
            # This is expected for new conversations or network issues
            pass

        # Fallback to zero UUID for new conversations
        return "00000000-0000-4000-8000-000000000000"


    def _build_message_payload(self, chat_id: str, prompt: str, attachment_paths: List[str] = None) -> tuple[str, str, dict]:
        """Build the URL, payload, and headers for a message request"""
        self._validate_attachments(attachment_paths)

        # Prepare attachments
        attachments = []
        files = []

        if attachment_paths:
            for path in attachment_paths:
                attachment = self._prepare_file_attachment(path, chat_id)
                if isinstance(attachment, dict):
                    attachments.append(attachment)
                elif isinstance(attachment, str):
                    files.append(attachment)

        # Build request
        url = f"{BASE_URL}/api/organizations/{self.organization_id}/chat_conversations/{chat_id}/completion"

        # Always use the correct parent UUID - this enables proper conversation continuation
        # for ALL scenarios (not just --continue flag)
        parent_uuid = self._get_last_message_uuid(chat_id)

        payload = {
            "prompt": prompt,
            "parent_message_uuid": parent_uuid,
            "timezone": self.timezone,
            "personalized_styles": DEFAULT_STYLES,
            "locale": "en-US",
            "tools": DEFAULT_TOOLS,
            "attachments": attachments,
            "files": files,
            "sync_sources": [],
            "rendering_mode": "messages"
        }

        if self.model_name:
            payload["model"] = self.model_name

        payload_json = dumps(payload, separators=(",", ":"))

        headers = self.get_headers("api",
            referer=f"{BASE_URL}/chat/{chat_id}",
            content_type="application/json",
            content_length=len(payload_json),
            accept="text/event-stream, text/event-stream"
        )

        return url, payload_json, headers

    def send_message(self, chat_id: str, prompt: str, attachment_paths: List[str] = None, stream: bool = False):
        """Send a message to a chat conversation, optionally streaming"""
        url, payload_json, headers = self._build_message_payload(chat_id, prompt, attachment_paths)

        if stream:
            return self._send_streaming(url, headers, payload_json)
        else:
            response = http_post(url, headers=headers, data=payload_json, timeout=self.timeout, impersonate="chrome110")

            # Decode response
            encoding = response.headers.get("Content-Encoding")
            decoded_content = self._decode_response(response.content, encoding)
            answer, model = self._parse_message_response(decoded_content)

            return SendMessageResponse(answer, response.status_code, response.content, model)

    def _send_streaming(self, url: str, headers: dict, payload_json: str):
        """Handle streaming response"""
        response = http_post(url, headers=headers, data=payload_json, timeout=self.timeout,
                           impersonate="chrome110", stream=True)

        if response.status_code != 200:
            raise ClaudeAPIError(f"HTTP {response.status_code}: {response.text}")

        # Process streaming response
        buffer = ""
        model_info = None

        try:
            # Use iter_content to get raw bytes as they arrive
            for chunk in response.iter_content(chunk_size=1):
                if chunk:
                    try:
                        # Try to decode the chunk
                        char = chunk.decode('utf-8')
                        buffer += char

                        # Process complete lines
                        while '\n' in buffer:
                            line, buffer = buffer.split('\n', 1)
                            if line.strip():
                                completion, data = self._parse_streaming_line(line.strip())

                                # Check for model information
                                if not model_info and data:
                                    if 'model' in data:
                                        model_info = data['model']
                                    elif 'stop_reason' in data and hasattr(self, '_current_model'):
                                        model_info = self._current_model

                                if completion:
                                    yield completion

                    except UnicodeDecodeError:
                        # Skip invalid UTF-8 bytes
                        continue

        except Exception as e:
            # If streaming fails, try regular request as fallback
            response = http_post(url.replace('stream=True', ''), headers=headers, data=payload_json, timeout=self.timeout, impersonate="chrome110")
            if response.status_code == 200:
                encoding = response.headers.get("Content-Encoding")
                decoded_content = self._decode_response(response.content, encoding)
                answer, model = self._parse_message_response(decoded_content)
                if answer:
                    yield answer
            else:
                handle_api_error(response, "Streaming and fallback request")

        # Handle any remaining buffer
        if buffer.strip():
            completion, data = self._parse_streaming_line(buffer.strip())
            if completion:
                yield completion

        # Store model info for potential future use
        if model_info:
            self._current_model = model_info

    def update_conversation_settings(self, chat_id: str, reasoning_mode: bool = False) -> bool:
        """Update conversation settings (like reasoning mode)"""
        url = f"{BASE_URL}/api/organizations/{self.organization_id}/chat_conversations/{chat_id}"

        settings = {}
        if reasoning_mode:
            settings["paprika_mode"] = "extended"
        else:
            settings["paprika_mode"] = None

        payload = {"settings": settings}
        payload_json = dumps(payload, separators=(",", ":"))

        headers = self.get_headers("api",
            referer=f"{BASE_URL}/chat/{chat_id}",
            content_type="application/json",
            content_length=len(payload_json)
        )

        # Add rendering_mode query parameter as seen in the HAR
        url_with_params = f"{url}?rendering_mode=raw"

        response = http_put(url_with_params, headers=headers, data=payload_json, timeout=self.timeout, impersonate="chrome110")

        return response.status_code in [200, 202]  # Accept both OK and Accepted




# ============================================================================
# CLI Interface
# ============================================================================

@click.group(invoke_without_command=True)
@click.pass_context
def cli(ctx):
    """Claude API client"""
    if ctx.invoked_subcommand is None:
        # Default to chat command for backward compatibility
        ctx.invoke(chat, prompt='')

@cli.command()
@click.option('--clear-cache', is_flag=True, help='Clear cache before fetching')
@click.option('-n', '--count', default=10, help='Number of conversations to show')
@click.option('--dates', is_flag=True, help='Show created and updated dates')
@click.option('--since', help='Show conversations since date (e.g., "2 days ago", "2024-01-01")')
@click.option('--until', help='Show conversations until date (e.g., "yesterday", "2024-12-31")')
@click.option('--after', help='Show conversations after date (alias for --since)')
@click.option('--before', help='Show conversations before date (alias for --until)')
def list(clear_cache, count, dates, since, until, after, before):
    """List conversations"""
    list_conversations(clear_cache, count, dates, since, until, after, before)

@cli.command()
@click.argument('chat_ids', nargs=-1, required=True)
def delete(chat_ids):
    """Delete conversations"""
    delete_conversations(builtin_list(chat_ids))

@cli.command()
@click.argument('chat_id')
def show(chat_id):
    """Show conversation in human-readable format"""
    show_conversation_cmd(chat_id)

@cli.command()
@click.argument('prompt', required=False, default='')
@click.option('--attach', multiple=True, help='File paths for attachments')
@click.option('--model', type=click.Choice(['opus', 'sonnet']), default='opus',
              help='Claude model to use')
@click.option('--id', 'chat_id', help='Chat ID to use')
@click.option('-c', '--continue', 'continue_last', is_flag=True, help='Continue last conversation')
@click.option('--reasoning', is_flag=True, help='Enable reasoning mode')
@click.option('--discard', is_flag=True, help='Discard chat after completion')
@click.option('-o', '--open-browser', is_flag=True, help='Open browser with chat')
@click.option('--stream', is_flag=True, help='Stream response in real-time')
def chat(prompt, attach, model, chat_id, continue_last, reasoning, discard, open_browser, stream):
    """Send message to chat"""
    chat_conversation(prompt, builtin_list(attach), model, chat_id, continue_last, reasoning, discard, open_browser, stream)

def list_conversations(clear_cache, count, dates, since, until, after, before):
    """Implementation for list command"""
    from datetime import datetime

    # Get session and client
    session = get_claude_session()
    client = ClaudeAPIClient(session, timeout=DEFAULT_TIMEOUT)

    conversations = client.get_all_conversations(use_cache=not clear_cache)

    # Apply date filters first (before limiting count)
    try:
        conversations = filter_conversations_by_date(
            conversations,
            since=since,
            until=until,
            after=after,
            before=before
        )
    except ValueError as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)

    # Sort by updated_at descending and limit
    conversations = sorted(conversations, key=lambda x: x.get("updated_at", ""), reverse=True)[:count]

    if conversations:
        # Helper function to format dates (defined once, outside loop)
        def format_date(date_str):
            dt = safe_date_parse(date_str, "conversation date")
            if dt:
                local_dt = dt.astimezone()
                return local_dt.strftime('%Y-%m-%dT%H:%M')
            return date_str or ""

        # Check if we should show summaries (only if there are non-empty ones)
        has_summaries = any(conv.get("summary", "") for conv in conversations)

        if dates:
            # Full format with dates
            if has_summaries:
                table_data = [
                    [conv.get("summary", ""), conv.get("name") or "(Untitled)",
                     "★" if conv.get("is_starred") else " ", format_date(conv.get("created_at")),
                     format_date(conv.get("updated_at")), conv["uuid"]]
                    for conv in conversations
                ]
            else:
                table_data = [
                    [conv.get("name") or "(Untitled)", "★" if conv.get("is_starred") else " ",
                     format_date(conv.get("created_at")), format_date(conv.get("updated_at")), conv["uuid"]]
                    for conv in conversations
                ]
        else:
            # Simple format: just name and uuid
            table_data = [
                [conv.get("name") or "(Untitled)", "★" if conv.get("is_starred") else " ", conv["uuid"]]
                for conv in conversations
            ]

        click.echo(tabulate(table_data, tablefmt="plain"))

def delete_conversations(chat_ids):
    """Implementation for delete command"""
    session = get_claude_session()
    client = ClaudeAPIClient(session, timeout=DEFAULT_TIMEOUT)

    deleted_chat_ids = []
    for chat_id in chat_ids:
        success = client.delete_chat(chat_id)
        if success:
            deleted_chat_ids.append(chat_id)
        click.echo(f"Chat {chat_id} {'deleted' if success else 'deletion failed'}")

    # Remove only the deleted conversations from cache
    if deleted_chat_ids:
        client.remove_conversations_from_cache(deleted_chat_ids)

def show_conversation_cmd(chat_id):
    """Implementation for show command"""
    session = get_claude_session()
    client = ClaudeAPIClient(session, timeout=DEFAULT_TIMEOUT)
    show_conversation(client, chat_id)

def chat_conversation(prompt, attach, model, chat_id, continue_last, reasoning, discard, open_browser, stream):
    """Implementation for chat command"""
    temp_files = []

    try:
        # Handle piped input
        if not sys.stdin.isatty():
            piped_input = sys.stdin.read().strip()
            if piped_input:
                tmp_file_path = create_temp_attachment(piped_input)
                temp_files.append(tmp_file_path)
                attach = builtin_list(attach) + [tmp_file_path]

        # Map model aliases to full names
        model_name = MODEL_ALIASES.get(model, model) if model else None

        # Get session and client
        session = get_claude_session()
        client = ClaudeAPIClient(session, model_name=model_name, timeout=DEFAULT_TIMEOUT)

        # Handle continue flag
        if continue_last:
            state_dir = user_state_dir('claude')
            last_chat_file = os.path.join(state_dir, 'last_conversation_id')
            if os.path.exists(last_chat_file):
                with open(last_chat_file, 'r') as f:
                    chat_id = f.read().strip()
            else:
                click.echo("No previous conversation found.", err=True)
                sys.exit(1)

        # Send message
        final_chat_id = send_chat_message(client, prompt, builtin_list(attach), chat_id, reasoning, discard, open_browser, stream)

    except (ClaudeAPIError, MessageRateLimitError, OverloadError) as e:
        click.echo(f"Claude API error: {e}", err=True)
        sys.exit(1)
    except Exception as e:
        click.echo(f"Unexpected error: {e}", err=True)
        sys.exit(1)
    finally:
        # Clean up temporary files
        for temp_file in temp_files:
            try:
                os.unlink(temp_file)
            except OSError:
                pass

def send_chat_message(client, prompt, attach, chat_id, reasoning, discard, open_browser, stream):
    """Send a chat message with the given parameters"""
    state_dir = user_state_dir('claude')
    last_chat_file = os.path.join(state_dir, 'last_conversation_id')
    os.makedirs(state_dir, exist_ok=True)

    # Create chat if no ID provided
    if not chat_id:
        chat_id = client.create_chat()
        if not chat_id:
            click.echo("Failed to create chat (message limit hit?)", err=True)
            sys.exit(1)

        # Update conversation settings if reasoning mode is requested
        if reasoning:
            if not client.update_conversation_settings(chat_id, reasoning_mode=True):
                click.echo("Warning: Failed to enable reasoning mode", err=True)

    # Send message
    try:
        if stream:
            # Stream mode
            has_output = False
            for chunk in client.send_message(chat_id, prompt, attach, stream=True):
                click.echo(chunk, nl=False)
                has_output = True

            if has_output:
                click.echo()  # Ensure newline after streaming

                # Save last conversation ID
                with open(last_chat_file, 'w') as f:
                    f.write(chat_id)

                # Handle post-message options
                if discard:
                    if client.delete_chat(chat_id):
                        client.remove_conversations_from_cache([chat_id])

                if open_browser:
                    webbrowser.open(f'https://claude.ai/chat/{chat_id}')
            else:
                click.echo("No response received from streaming", err=True)
        else:
            # Non-stream mode
            response = client.send_message(chat_id, prompt, attach)

            if response.answer:
                click.echo(response.answer)

                # Save last conversation ID
                with open(last_chat_file, 'w') as f:
                    f.write(chat_id)

                # Handle post-message options
                if discard:
                    if client.delete_chat(chat_id):
                        client.remove_conversations_from_cache([chat_id])

                if open_browser:
                    webbrowser.open(f'https://claude.ai/chat/{chat_id}')
            else:
                click.echo(f"Error {response.status_code}: {response.raw_answer}", err=True)

    except MessageRateLimitError as e:
        click.echo(f"Message limit hit, resets at {e.reset_date}", err=True)
        sys.exit(1)

    return chat_id

def main():
    # Handle backward compatibility by inserting 'chat' for non-subcommands
    if len(sys.argv) > 1 and sys.argv[1] not in ['list', 'delete', 'show', 'chat'] and not sys.argv[1] in ['--help', '-h']:
        sys.argv.insert(1, 'chat')
    cli()


def parse_relative_date(date_str: str) -> datetime:
    """Parse git-style relative dates using parsedatetime library"""
    import parsedatetime
    from datetime import datetime

    cal = parsedatetime.Calendar()
    time_struct, parse_status = cal.parse(date_str)

    if parse_status == 0:
        raise ValueError(f"Could not parse date: {date_str}")

    return datetime(*time_struct[:6])


def filter_conversations_by_date(conversations: List[Dict], since: str = None, until: str = None,
                                after: str = None, before: str = None) -> List[Dict]:
    """Filter conversations by date range using git-style date parsing"""
    # Handle aliases
    since = since or after
    until = until or before

    if not since and not until:
        return conversations

    filtered = []
    for conv in conversations:
        updated_at = conv.get('updated_at', '')
        if not updated_at:
            continue

        # Parse the conversation date
        conv_date = safe_date_parse(updated_at, "conversation date")
        if not conv_date:
            continue

        # Apply filters
        if since:
            since_date = parse_relative_date(since)
            if conv_date < since_date:
                continue

        if until:
            until_date = parse_relative_date(until)
            if conv_date > until_date:
                continue

        filtered.append(conv)

    return filtered


def show_conversation(client: ClaudeAPIClient, chat_id: str):
    """Show conversation in human-readable format"""
    chat_data = client.get_chat_data(chat_id)

    # Print conversation metadata
    print(f"Conversation: {chat_data.get('name', '(Untitled)')}")
    print(f"ID: {chat_data.get('uuid', chat_id)}")
    print(f"Created: {chat_data.get('created_at', 'Unknown')}")
    print(f"Updated: {chat_data.get('updated_at', 'Unknown')}")
    print(f"Starred: {'Yes' if chat_data.get('is_starred', False) else 'No'}")

    settings = chat_data.get('settings', {})
    if settings.get('paprika_mode') == 'extended':
        print("Reasoning Mode: Enabled")

    print(f"Summary: {chat_data.get('summary', 'No summary')}")
    print("\n" + "="*80 + "\n")

    # Print messages
    messages = chat_data.get('chat_messages', [])
    if not messages:
        print("No messages in this conversation.")
        return

    for msg in messages:
        sender = msg.get('sender', 'unknown')
        content = msg.get('text', '')
        created_at = msg.get('created_at', '')

        if sender == 'human':
            print(f"👤 You ({created_at}):")
            print(f"{content}\n")
        elif sender == 'assistant':
            print(f"🤖 Claude ({created_at}):")
            print(f"{content}\n")


def handle_chat_conversation(client: ClaudeAPIClient, args, prompt: str):
    """Handle sending a message and managing conversation state"""
    # Determine chat ID
    state_dir = user_state_dir('claude')
    last_chat_file = os.path.join(state_dir, 'last_conversation_id')

    os.makedirs(state_dir, exist_ok=True)

    if args.id:
        if args.id.lower() == 'last':
            if os.path.exists(last_chat_file):
                with open(last_chat_file, 'r') as f:
                    chat_id = f.read().strip()
            else:
                print("No previous conversation found.")
                sys.exit(1)
        else:
            chat_id = args.id
    else:
        chat_id = client.create_chat()
        if not chat_id:
            print("Failed to create chat (message limit hit?)")
            sys.exit(1)

        # Update conversation settings if reasoning mode is requested
        if args.reasoning:
            if not client.update_conversation_settings(chat_id, reasoning_mode=True):
                print("Warning: Failed to enable reasoning mode", file=sys.stderr)

    # Send message
    try:
        if args.stream:
            # Stream mode
            has_output = False
            for chunk in client.send_message(chat_id, prompt, args.attach, stream=True):
                print(chunk, end='', flush=True)
                has_output = True

            if has_output:
                print()  # Ensure newline after streaming


                # Save last conversation ID
                with open(last_chat_file, 'w') as f:
                    f.write(chat_id)

                # Handle post-message options
                if args.discard:
                    if client.delete_chat(chat_id):
                        client.remove_conversations_from_cache([chat_id])

                if args.open_browser:
                    webbrowser.open(f'https://claude.ai/chat/{chat_id}')
            else:
                print("No response received from streaming")
        else:
            # Non-stream mode
            response = client.send_message(chat_id, prompt, args.attach)

            if response.answer:
                print(response.answer)


                # Save last conversation ID
                with open(last_chat_file, 'w') as f:
                    f.write(chat_id)

                # Handle post-message options
                if args.discard:
                    if client.delete_chat(chat_id):
                        client.remove_conversations_from_cache([chat_id])

                if args.open_browser:
                    webbrowser.open(f'https://claude.ai/chat/{chat_id}')
            else:
                print(f"Error {response.status_code}: {response.raw_answer}")

    except MessageRateLimitError as e:
        print(f"Message limit hit, resets at {e.reset_date}")
        sys.exit(1)

    return chat_id


if __name__ == "__main__":
    main()