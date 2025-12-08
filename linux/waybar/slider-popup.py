#!/usr/bin/env python3
"""Individual slider popup for waybar - brightness, volume, or kbd-backlight."""

import gi
import subprocess
import sys

gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, GtkLayerShell, GLib


class SliderPopup(Gtk.Window):
    def __init__(self, control_type, x_position=None):
        super().__init__(title=f"{control_type} Control")
        self.control_type = control_type

        # Set up layer shell
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 3)
        # Position based on control type (right margin from screen edge)
        margins = {"volume": 195, "brightness": 160}
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, margins.get(control_type, 180))
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)

        # Main container - single horizontal row
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        main_box.set_margin_top(8)
        main_box.set_margin_bottom(8)
        main_box.set_margin_start(12)
        main_box.set_margin_end(12)
        self.add(main_box)

        # Get control functions based on type
        if control_type == "brightness":
            self.icon = "󰃟"
            self.get_value = self.get_brightness
            self.set_value = self.set_brightness
        elif control_type == "volume":
            self.icon = "󰕾"
            self.get_value = self.get_volume
            self.set_value = self.set_volume
        else:
            print(f"Unknown control type: {control_type}")
            sys.exit(1)

        # Get initial value
        value = self.get_value()
        if value is None:
            print(f"Could not get {control_type} value")
            sys.exit(1)

        # Icon
        icon_label = Gtk.Label(label=self.icon)
        icon_label.get_style_context().add_class("slider-icon")
        icon_label.set_valign(Gtk.Align.CENTER)
        main_box.pack_start(icon_label, False, False, 0)

        # Slider
        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 5)
        self.scale.set_draw_value(False)
        self.scale.set_value(value)
        self.scale.set_size_request(120, -1)
        self.scale.connect("value-changed", self.on_value_changed)
        main_box.pack_start(self.scale, False, False, 0)

        # Value label
        self.value_label = Gtk.Label(label=f"{int(value)}%")
        self.value_label.get_style_context().add_class("slider-value")
        self.value_label.set_valign(Gtk.Align.CENTER)
        self.value_label.set_width_chars(4)
        main_box.pack_start(self.value_label, False, False, 0)

        # Close on click outside (button press on window but not on controls)
        self.connect("button-press-event", self.on_button_press)

        # Load CSS
        self.load_css()
        self.show_all()

        # Close on focus loss or Escape key
        self.connect("focus-out-event", lambda w, e: self.close())
        self.connect("key-press-event", self.on_key_press)

        # Auto-close after 5 seconds of no interaction
        self.timeout_id = GLib.timeout_add_seconds(5, self.auto_close)
        self.scale.connect("button-press-event", self.reset_timeout)
        self.scale.connect("button-release-event", self.reset_timeout)

    def on_key_press(self, widget, event):
        from gi.repository import Gdk
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def reset_timeout(self, *args):
        if self.timeout_id:
            GLib.source_remove(self.timeout_id)
        self.timeout_id = GLib.timeout_add_seconds(3, self.auto_close)
        return False

    def auto_close(self):
        self.close()
        return False

    def on_button_press(self, widget, event):
        # Reset timeout on any interaction
        self.reset_timeout()
        return False

    def on_value_changed(self, scale):
        value = int(scale.get_value())
        self.set_value(value)
        self.value_label.set_text(f"{value}%")
        self.reset_timeout()

    def load_css(self):
        css = b"""
        window {
            background: rgba(20, 20, 20, 0.95);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 3px;
        }
        .slider-icon {
            font-size: 20px;
            color: #888888;
            min-width: 28px;
        }
        .slider-value {
            color: #888888;
            font-size: 12px;
            font-weight: bold;
        }
        scale {
            min-height: 6px;
        }
        scale trough {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
            min-height: 6px;
        }
        scale highlight {
            background: #00ff00;
            border-radius: 3px;
        }
        scale slider {
            background: #ffffff;
            border-radius: 50%;
            min-width: 14px;
            min-height: 14px;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            self.get_screen(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def get_brightness(self):
        for device in ['apple-panel-bl', 'intel_backlight', 'amdgpu_bl0']:
            try:
                result = subprocess.run(
                    ['brightnessctl', '-d', device, '-m'],
                    capture_output=True, text=True
                )
                if result.returncode == 0:
                    self._brightness_device = device
                    return int(result.stdout.split(',')[3].rstrip('%'))
            except Exception:
                pass
        return None

    def set_brightness(self, value):
        if hasattr(self, '_brightness_device'):
            subprocess.run(['brightnessctl', '-d', self._brightness_device, 'set', f'{value}%'])

    def get_volume(self):
        try:
            result = subprocess.run(
                ['wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@'],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                # Output format: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
                parts = result.stdout.split()
                if len(parts) >= 2:
                    return int(float(parts[1]) * 100)
        except Exception:
            pass
        return 50

    def set_volume(self, value):
        subprocess.run(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', f'{value}%'])

def kill_other_popups(current_type):
    """Kill other slider popups (mutual exclusion)."""
    import os

    for slider_type in ["brightness", "volume"]:
        if slider_type == current_type:
            continue
        pid_file = f"/tmp/waybar-slider-{slider_type}.pid"
        if os.path.exists(pid_file):
            try:
                with open(pid_file, 'r') as f:
                    pid = int(f.read().strip())
                os.kill(pid, 15)
                os.remove(pid_file)
            except (ProcessLookupError, ValueError, FileNotFoundError):
                pass


def main():
    if len(sys.argv) < 2:
        print("Usage: slider-popup.py <brightness|volume|kbd-backlight>")
        sys.exit(1)

    control_type = sys.argv[1]

    # Check if already running for this control type
    import os
    pid_file = f"/tmp/waybar-slider-{control_type}.pid"

    if os.path.exists(pid_file):
        try:
            with open(pid_file, 'r') as f:
                old_pid = int(f.read().strip())
            # Check if process is still running
            os.kill(old_pid, 0)
            # Process exists, kill it (toggle behavior)
            os.kill(old_pid, 15)
            os.remove(pid_file)
            sys.exit(0)
        except (ProcessLookupError, ValueError):
            # Process not running, continue
            pass

    # Kill other popups (mutual exclusion)
    kill_other_popups(control_type)

    # Write our PID
    with open(pid_file, 'w') as f:
        f.write(str(os.getpid()))

    try:
        win = SliderPopup(control_type)
        win.connect("destroy", Gtk.main_quit)
        Gtk.main()
    finally:
        if os.path.exists(pid_file):
            os.remove(pid_file)


if __name__ == "__main__":
    main()
