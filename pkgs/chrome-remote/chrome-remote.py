#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["platformdirs"]
# ///
"""
Chrome Debug Launcher

Launches Chrome with remote debugging enabled using a dedicated profile.
Creates the profile if it doesn't exist, or reuses it if it does.
"""

import argparse
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional

from platformdirs import user_data_dir


def find_chrome_executable() -> Optional[str]:
    """Find Chrome executable based on the current platform."""
    system = platform.system().lower()

    if system == "darwin":  # macOS
        paths = [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "/Applications/Chromium.app/Contents/MacOS/Chromium",
        ]
    elif system == "linux":
        paths = [
            "/usr/bin/google-chrome",
            "/usr/bin/google-chrome-stable",
            "/usr/bin/chromium",
            "/usr/bin/chromium-browser",
            "/snap/bin/chromium",
        ]
    elif system == "windows":
        paths = [
            os.path.expandvars(r"%PROGRAMFILES%\Google\Chrome\Application\chrome.exe"),
            os.path.expandvars(r"%PROGRAMFILES(X86)%\Google\Chrome\Application\chrome.exe"),
            os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"),
        ]
    else:
        return None

    for path in paths:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path

    # Try to find via PATH
    for name in ["google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "chrome"]:
        path = shutil.which(name)
        if path:
            return path

    return None


def get_debug_profile_dir(profile_name: str = "chrome-debug") -> Path:
    """Get the debug profile directory using platformdirs."""
    app_data_dir = user_data_dir("chrome-debug-launcher", "dev-tools")
    return Path(app_data_dir) / profile_name


def ensure_profile_exists(profile_dir: Path) -> None:
    """Create the profile directory if it doesn't exist."""
    profile_dir.mkdir(parents=True, exist_ok=True)

    # Create a simple preferences file to avoid first-run prompts
    prefs_file = profile_dir / "Default" / "Preferences"
    prefs_file.parent.mkdir(exist_ok=True)

    if not prefs_file.exists():
        prefs_content = '''
{
   "browser": {
      "check_default_browser": false
   },
   "distribution": {
      "import_bookmarks": false,
      "import_history": false,
      "import_search_engine": false,
      "make_chrome_default_for_user": false,
      "skip_first_run_ui": true
   },
   "first_run_tabs": [ "chrome://newtab/" ]
}
'''.strip()
        prefs_file.write_text(prefs_content)


def launch_chrome_debug(chrome_path: str, profile_dir: Path, port: int, additional_args: list = None) -> subprocess.Popen:
    """Launch Chrome with remote debugging enabled."""
    if additional_args is None:
        additional_args = []

    args = [
        chrome_path,
        f"--remote-debugging-port={port}",
        f"--user-data-dir={profile_dir}",
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-background-timer-throttling",
        "--disable-backgrounding-occluded-windows",
        "--disable-renderer-backgrounding",
        "--disable-features=TranslateUI",
        "--disable-ipc-flooding-protection",
    ] + additional_args

    try:
        process = subprocess.Popen(args,
                                 stdout=subprocess.DEVNULL,
                                 stderr=subprocess.DEVNULL,
                                 start_new_session=True)
        return process
    except Exception as e:
        raise RuntimeError(f"Failed to launch Chrome: {e}")


def main():
    parser = argparse.ArgumentParser(description="Launch Chrome with remote debugging enabled")
    parser.add_argument("--url", "-u",
                       help="URL to open on launch")
    parser.add_argument("--headless", action="store_true",
                       help="Run Chrome in headless mode")

    args = parser.parse_args()

    # Find Chrome executable
    chrome_path = find_chrome_executable()
    if not chrome_path:
        print("Error: Could not find Chrome executable", file=sys.stderr)
        sys.exit(1)


    # Setup profile directory
    profile_dir = get_debug_profile_dir("chrome-debug")

    try:
        ensure_profile_exists(profile_dir)
    except Exception as e:
        print(f"Error: Could not create profile directory: {e}", file=sys.stderr)
        sys.exit(1)

    # Prepare additional arguments
    additional_args = []
    if args.headless:
        additional_args.append("--headless")
    if args.url:
        additional_args.append(args.url)

    # Launch Chrome
    try:
        process = launch_chrome_debug(chrome_path, profile_dir, 9222, additional_args)
        print(f"Chrome launched with remote debugging on port 9222")
        print(f"Debug URL: http://localhost:9222")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()