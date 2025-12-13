#!/usr/bin/env -S uv run --script --quiet
"""Identify music using Shazam API from audio input or files."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "numpy>=2.2",
#   "pyaudio>=0.2.14",
#   "rich>=14.0",
#   "shazamio>=0.8",
# ]
# ///


import sys
import time
import asyncio
import argparse
import wave
import tempfile
import os
import threading
import signal
from asyncio import Queue

# Global shutdown flag
shutdown_flag = False

import pyaudio
import numpy as np
from shazamio import Shazam
from rich.console import Console
from rich.live import Live
from rich.align import Align


class AudioCapture:
    def __init__(self, duration=5, sample_rate=44100, channels=1):
        self.duration = duration
        self.sample_rate = sample_rate
        self.channels = channels
        self.chunk_size = 1024
        self.audio = pyaudio.PyAudio()
        self.current_levels = [0.0] * 20  # Store current audio levels (float for smooth decay)
        self.visualizer_running = False
        self.auto_gain = 1.0  # Auto-scaling factor
        self.peak_history = []  # Track recent peaks for auto-scaling
        self.display_levels = [0.0] * 20  # Smoothed levels for display

        # Rolling buffer for longer samples after first match
        self.buffer_duration = 15  # Keep 15 seconds of audio
        self.audio_buffer = []
        self.buffer_max_frames = int(self.sample_rate / self.chunk_size * self.buffer_duration)
        self.has_matched = False

        # Rich console for proper terminal handling
        self.console = Console()
        self.live_display = None

    def update_visualizer(self, audio_data):
        """Update visualizer with actual audio levels"""
        try:
            # Convert bytes to numpy array
            audio_array = np.frombuffer(audio_data, dtype=np.int16)

            if len(audio_array) == 0:
                return

            # Calculate overall RMS for auto-gain
            overall_rms = np.sqrt(np.mean(audio_array.astype(np.float64)**2))

            # Update peak history (keep last 20 chunks)
            self.peak_history.append(overall_rms)
            if len(self.peak_history) > 20:
                self.peak_history.pop(0)

            # Calculate auto-gain based on recent peaks
            if self.peak_history:
                recent_peak = np.percentile(self.peak_history, 90)  # 90th percentile
                if recent_peak > 100:  # Avoid divide by zero and very quiet signals
                    # Target peak of around 5000 for good visualization
                    target_peak = 5000
                    self.auto_gain = target_peak / recent_peak
                    # Limit gain to reasonable range
                    self.auto_gain = np.clip(self.auto_gain, 0.5, 50.0)

            # Split into frequency bands with bass bias
            # Create non-linear band distribution favoring lower frequencies
            total_samples = len(audio_array)

            for i in range(20):
                # Non-linear distribution: more samples for lower frequencies
                # First 10 bands get bigger chunks (bass/mids)
                # Last 10 bands get smaller chunks (highs)
                if i < 10:
                    # Bass/low-mids: use larger chunks
                    band_start_ratio = (i / 10) ** 1.5  # Slower progression
                    band_end_ratio = ((i + 1) / 10) ** 1.5
                    start = int(band_start_ratio * total_samples * 0.7)  # Use 70% for first 10 bands
                    end = int(band_end_ratio * total_samples * 0.7)
                else:
                    # Highs: use remaining 30% split among last 10 bands
                    high_band_idx = i - 10
                    band_start_ratio = high_band_idx / 10
                    band_end_ratio = (high_band_idx + 1) / 10
                    start = int(total_samples * 0.7 + band_start_ratio * total_samples * 0.3)
                    end = int(total_samples * 0.7 + band_end_ratio * total_samples * 0.3)

                start = max(0, min(start, total_samples - 1))
                end = max(start + 1, min(end, total_samples))

                if start < total_samples:
                    # Calculate RMS (volume) for this band
                    band_data = audio_array[start:end].astype(np.float64)
                    if len(band_data) > 0:
                        # Compute RMS safely
                        mean_squared = np.mean(band_data**2)
                        if mean_squared >= 0:
                            rms = np.sqrt(mean_squared)
                            # Apply auto-gain and normalize to 0-7
                            scaled_rms = rms * self.auto_gain
                            level = min(scaled_rms / 1000, 7.0)  # Keep as float

                            # Apply minimum threshold - only show if above noise floor
                            threshold = 0.8  # Minimum level to display (adjust as needed)
                            if level < threshold:
                                level = 0.0
                            else:
                                # Rescale from threshold to 4 levels max
                                level = (level - threshold) / (7.0 - threshold) * 4.0

                            self.current_levels[i] = level
                        else:
                            self.current_levels[i] = 0.0
                    else:
                        self.current_levels[i] = 0.0
                else:
                    self.current_levels[i] = 0.0
        except Exception:
            # If any error, just skip visualization update
            pass

        # Apply attack/decay smoothing (slightly faster)
        attack_rate = 0.6  # Medium-fast rise
        decay_rate = 0.1   # Medium fall

        for i in range(20):
            current = self.current_levels[i]
            display = self.display_levels[i]

            if current > display:
                # Attack - fast rise
                self.display_levels[i] = display + (current - display) * attack_rate
            else:
                # Decay - slow fall
                self.display_levels[i] = display + (current - display) * decay_rate

            # Ensure we don't go below 0
            self.display_levels[i] = max(0.0, self.display_levels[i])

    def draw_visualizer(self):
        """Draw single-line audio meter with level-based coloring using Rich"""
        # Just 4 Braille heights
        bars = ['⡀', '⡄', '⡆', '⡇']

        output = []
        for i, level_float in enumerate(self.display_levels):
            level = int(round(level_float))  # Now 0-4 range

            if level == 0:
                output.append(' ')
            else:
                # Direct mapping: level 1-4 to bars 0-3
                bar = bars[level - 1]

                # Simple 4-level coloring
                if level == 1:
                    color = "bold red"
                elif level == 2:
                    color = "bold bright_red"
                elif level == 3:
                    color = "bold yellow"
                else:  # level 4
                    color = "bold bright_green"

                # Rich will handle the color formatting
                output.append(f"[{color}]{bar}[/{color}]")

        # Create centered display using Rich
        visualizer_text = ''.join(output)

        # Use Rich's Live display if available, otherwise create one
        if self.live_display is None:
            self.live_display = Live(
                Align.center(visualizer_text),
                console=self.console,
                refresh_per_second=30,
                transient=True
            )
            self.live_display.start()
        else:
            # Update the live display
            self.live_display.update(Align.center(visualizer_text))

    def capture_audio(self, show_animation=True):
        # Use longer duration after first match for better accuracy
        current_duration = self.buffer_duration if self.has_matched else max(self.duration, 8)

        try:
            # Try to find the built-in MacBook microphone first
            input_device_index = None
            device_sample_rate = self.sample_rate

            # First pass: look for built-in MacBook microphone
            for i in range(self.audio.get_device_count()):
                info = self.audio.get_device_info_by_index(i)
                if (info['maxInputChannels'] > 0 and
                    'macbook' in info['name'].lower() and
                    'microphone' in info['name'].lower()):
                    input_device_index = i
                    device_sample_rate = int(info['defaultSampleRate'])
                    break

            # Second pass: any real microphone (not virtual audio devices)
            if input_device_index is None:
                for i in range(self.audio.get_device_count()):
                    info = self.audio.get_device_info_by_index(i)
                    if (info['maxInputChannels'] > 0 and
                        'microphone' in info['name'].lower() and
                        'blackhole' not in info['name'].lower()):
                        input_device_index = i
                        device_sample_rate = int(info['defaultSampleRate'])
                        break

            stream = self.audio.open(
                format=pyaudio.paInt16,
                channels=self.channels,
                rate=device_sample_rate,
                input=True,
                input_device_index=input_device_index,
                frames_per_buffer=self.chunk_size
            )
        except Exception as e:
            print(f"\n❌ Error: Cannot access microphone.", file=sys.stderr)
            print(f"   This is likely a permissions issue on macOS.", file=sys.stderr)
            print(f"   Please check System Preferences > Security & Privacy > Privacy > Microphone", file=sys.stderr)
            print(f"   and ensure Terminal/iTerm is allowed to access the microphone.\n", file=sys.stderr)
            print(f"   Technical error: {e}", file=sys.stderr)
            raise

        frames = []
        frames_needed = int(device_sample_rate / self.chunk_size * current_duration)

        for i in range(frames_needed):
            # Check shutdown flag
            if shutdown_flag:
                break

            data = stream.read(self.chunk_size, exception_on_overflow=False)
            frames.append(data)

            # Add to rolling buffer
            self.audio_buffer.append(data)
            if len(self.audio_buffer) > self.buffer_max_frames:
                self.audio_buffer.pop(0)

            # Update visualizer every few chunks to avoid too much processing
            if show_animation and i % 3 == 0:
                self.update_visualizer(data)
                self.draw_visualizer()

        stream.stop_stream()
        stream.close()

        # Rich handles clearing automatically

        # After first match, use rolling buffer instead of just current capture
        if self.has_matched and len(self.audio_buffer) >= self.buffer_max_frames:
            return b''.join(self.audio_buffer), device_sample_rate
        else:
            return b''.join(frames), device_sample_rate

    def save_to_file(self, audio_data, filename, sample_rate=None):
        with wave.open(filename, 'wb') as wf:
            wf.setnchannels(self.channels)
            wf.setsampwidth(self.audio.get_sample_size(pyaudio.paInt16))
            wf.setframerate(sample_rate or self.sample_rate)
            wf.writeframes(audio_data)

    def close(self):
        if self.live_display:
            self.live_display.stop()
        self.audio.terminate()

def format_result(result):
    if not result or 'track' not in result:
        return "No match found"

    track = result['track']
    title = track.get('title', 'Unknown')
    subtitle = track.get('subtitle', 'Unknown Artist')

    # Colors for different parts
    title_color = '\033[97m'  # bright white
    artist_color = '\033[94m'  # blue
    album_color = '\033[90m'  # gray
    year_color = '\033[33m'   # yellow
    reset = '\033[0m'

    output = f"{title_color}{title}{reset} - {artist_color}{subtitle}{reset}"

    # Add metadata with colors
    album = None
    year = None

    if 'sections' in track:
        for section in track['sections']:
            if section.get('type') == 'SONG' and 'metadata' in section:
                for item in section['metadata']:
                    if item.get('title') == 'Album':
                        album = item.get('text', 'Unknown')
                    elif item.get('title') == 'Released':
                        year = item.get('text', 'Unknown')

    if album:
        output += f" {album_color}{album}{reset}"
    if year:
        output += f" {year_color}{year}{reset}"

    return output

def are_tracks_similar(result1, result2):
    """Check if tracks are the same base song (handles remixes, versions, etc.)"""
    if not result1 or not result2:
        return False

    # Extract track data from results
    track1 = result1.get('track') if isinstance(result1, dict) else None
    track2 = result2.get('track') if isinstance(result2, dict) else None

    if not track1 or not track2:
        return False

    def extract_base_song(track):
        import re

        title = track.get('title', '')
        subtitle = track.get('subtitle', '')  # Usually the artist

        # Get first word of artist (main artist)
        artist = subtitle.split()[0] if subtitle else ""

        # Clean title: remove remix/version indicators
        base_title = re.sub(r'\s*\([^)]*remix[^)]*\)', '', title, flags=re.I)
        base_title = re.sub(r'\s*\([^)]*version[^)]*\)', '', base_title, flags=re.I)
        base_title = re.sub(r'\s*\([^)]*edit[^)]*\)', '', base_title, flags=re.I)
        base_title = re.sub(r'\s*\([^)]*mix[^)]*\)', '', base_title, flags=re.I)
        base_title = re.sub(r'\s*\(feat\.?[^)]*\)', '', base_title, flags=re.I)
        base_title = re.sub(r'\s*feat\.?\s+.*$', '', base_title, flags=re.I)

        # Clean up whitespace
        base_title = re.sub(r'\s+', ' ', base_title).strip()

        return f"{base_title}|{artist}".lower()

    base1 = extract_base_song(track1)
    base2 = extract_base_song(track2)

    return base1 == base2

async def recognize_audio(shazam, audio_file_path):
    try:
        result = await shazam.recognize(audio_file_path)
        return result
    except Exception as e:
        print(f"Recognition error: {e}", file=sys.stderr)
        return None

async def main():
    parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--chunk", type=int, default=8, help="Audio chunk size in seconds")
    parser.add_argument("--continuous", action="store_true", help="Continue listening after first match")
    parser.add_argument("--quiet", action="store_true", help="No animations, only output matches")
    parser.add_argument("file", nargs="?", help="Audio file to recognize")

    args = parser.parse_args()

    shazam = Shazam()

    if args.file:
        if not os.path.exists(args.file):
            print(f"File not found: {args.file}", file=sys.stderr)
            sys.exit(1)

        result = await recognize_audio(shazam, args.file)
        print(format_result(result))
        return

    audio_capture = AudioCapture(duration=args.chunk)

    # Audio queue for passing chunks between capture and recognition
    audio_queue = Queue(maxsize=2)

    current_match = None
    match_lock = asyncio.Lock()


    async def continuous_capture():
        """Continuously capture audio chunks and queue them"""
        while not shutdown_flag:
            # Always show animation if not quiet
            show_anim = not args.quiet

            try:
                audio_data, sample_rate = await asyncio.wait_for(
                    asyncio.get_event_loop().run_in_executor(
                        None, audio_capture.capture_audio, show_anim
                    ),
                    timeout=30.0  # 30 second timeout
                )
                # Check if capture was interrupted (empty data or shutdown)
                if not audio_data or shutdown_flag:
                    return
            except asyncio.TimeoutError:
                print(f"\n❌ Timeout: Microphone access seems to be blocked.", file=sys.stderr)
                print(f"   Please check System Settings > Privacy & Security > Microphone", file=sys.stderr)
                print(f"   and ensure your terminal app has microphone access.\n", file=sys.stderr)
                return
            except Exception as e:
                print(f"\n❌ Audio capture error: {e}", file=sys.stderr)
                return

            # Save to temp file
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
                audio_capture.save_to_file(audio_data, tmp_file.name, sample_rate)
                await audio_queue.put(tmp_file.name)

    async def continuous_recognize():
        """Continuously process audio from queue"""
        nonlocal current_match
        last_match_result = None

        while not shutdown_flag:
            try:
                # Get audio file from queue with timeout to check shutdown flag
                audio_file = await asyncio.wait_for(audio_queue.get(), timeout=0.5)
            except asyncio.TimeoutError:
                continue

            try:
                result = await recognize_audio(shazam, audio_file)

                if result and 'track' in result:
                    formatted = format_result(result)

                    # Check if this is truly a different track
                    if not last_match_result or not are_tracks_similar(result, last_match_result):
                        # Clear visualizer line and print title
                        print(f"\r{' ' * 80}\r{formatted}", flush=True)
                        last_match_result = result
                        # Mark that we've had a successful match for better sampling
                        audio_capture.has_matched = True
                        async with match_lock:
                            current_match = formatted

                        # Exit on first match (default behavior) unless continuous is set
                        if not args.continuous:
                            return

                    # Similar match - keep current_match but don't print
                    else:
                        async with match_lock:
                            current_match = formatted
                else:
                    # No match - if we had a match before, it ended
                    async with match_lock:
                        if current_match is not None:
                            current_match = None

            finally:
                # Clean up temp file
                try:
                    os.unlink(audio_file)
                except:
                    pass

    # Start both tasks concurrently
    capture_task = asyncio.create_task(continuous_capture())
    recognize_task = asyncio.create_task(continuous_recognize())

    # Wait for recognition to complete (or run forever if continuous)
    while not shutdown_flag:
        if recognize_task.done():
            break
        await asyncio.sleep(0.1)

    # Cancel tasks and close audio
    if capture_task and not capture_task.done():
        capture_task.cancel()
    if recognize_task and not recognize_task.done():
        recognize_task.cancel()

    # Wait a bit for tasks to clean up
    if capture_task or recognize_task:
        await asyncio.sleep(0.1)

    audio_capture.close()

def signal_handler(signum, frame):
    global shutdown_flag
    shutdown_flag = True

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    asyncio.run(main())