#!/usr/bin/env python3
"""GTK Control Center popup for Waybar with sliders for brightness, volume, and keyboard backlight."""

import gi
import subprocess
import sys

gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, GtkLayerShell


class ControlCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="Control Center")

        # Set up layer shell
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 3)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 10)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)

        self.set_default_size(300, -1)

        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        main_box.set_margin_top(16)
        main_box.set_margin_bottom(16)
        main_box.set_margin_start(16)
        main_box.set_margin_end(16)
        self.add(main_box)

        # Screen brightness
        self.brightness_row = self.create_slider_row(
            "󰃟", "Screen Brightness",
            self.get_brightness, self.set_brightness
        )
        if self.brightness_row:
            main_box.pack_start(self.brightness_row, False, False, 0)

        # Volume
        self.volume_row = self.create_slider_row(
            "󰕾", "Volume",
            self.get_volume, self.set_volume
        )
        if self.volume_row:
            main_box.pack_start(self.volume_row, False, False, 0)

        # Keyboard backlight
        self.kbd_row = self.create_slider_row(
            "󰌌", "Keyboard Backlight",
            self.get_kbd_backlight, self.set_kbd_backlight
        )
        if self.kbd_row:
            main_box.pack_start(self.kbd_row, False, False, 0)

        # Load CSS
        self.load_css()

        self.show_all()

        # Close on focus loss or Escape key
        self.connect("focus-out-event", lambda w, e: self.close())
        self.connect("key-press-event", self.on_key_press)

    def on_key_press(self, widget, event):
        from gi.repository import Gdk
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def load_css(self):
        css = b"""
        window {
            background: rgba(20, 20, 20, 0.95);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .slider-row {
            padding: 8px 0;
        }
        .slider-icon {
            font-size: 18px;
            color: #888888;
            min-width: 24px;
        }
        .slider-label {
            color: #666666;
            font-size: 11px;
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

    def create_slider_row(self, icon, label, get_func, set_func):
        try:
            value = get_func()
            if value is None:
                return None
        except Exception:
            return None

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.get_style_context().add_class("slider-row")

        icon_label = Gtk.Label(label=icon)
        icon_label.get_style_context().add_class("slider-icon")
        row.pack_start(icon_label, False, False, 0)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        name_label = Gtk.Label(label=label)
        name_label.get_style_context().add_class("slider-label")
        name_label.set_halign(Gtk.Align.START)
        header.pack_start(name_label, True, True, 0)

        value_label = Gtk.Label(label=f"{value}%")
        value_label.get_style_context().add_class("slider-label")
        header.pack_end(value_label, False, False, 0)
        vbox.pack_start(header, False, False, 0)

        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 5)
        scale.set_draw_value(False)
        scale.set_value(value)
        scale.set_size_request(200, -1)

        def on_change(s):
            v = int(s.get_value())
            set_func(v)
            value_label.set_text(f"{v}%")

        scale.connect("value-changed", on_change)
        vbox.pack_start(scale, False, False, 0)

        row.pack_start(vbox, True, True, 0)
        return row

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

    def get_kbd_backlight(self):
        try:
            result = subprocess.run(
                ['brightnessctl', '-d', 'kbd_backlight', '-m'],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                return int(result.stdout.split(',')[3].rstrip('%'))
        except Exception:
            pass
        return None

    def set_kbd_backlight(self, value):
        subprocess.run(['brightnessctl', '-d', 'kbd_backlight', 'set', f'{value}%'])


if __name__ == "__main__":
    import os
    import signal

    pid_file = "/tmp/waybar-control-center.pid"

    # Toggle: if already running, kill it
    if os.path.exists(pid_file):
        try:
            with open(pid_file, 'r') as f:
                old_pid = int(f.read().strip())
            os.kill(old_pid, 0)  # Check if running
            os.kill(old_pid, signal.SIGTERM)  # Kill it
            os.remove(pid_file)
            sys.exit(0)
        except (ProcessLookupError, ValueError, FileNotFoundError):
            pass

    # Write our PID
    with open(pid_file, 'w') as f:
        f.write(str(os.getpid()))

    try:
        win = ControlCenter()
        win.connect("destroy", Gtk.main_quit)
        Gtk.main()
    finally:
        if os.path.exists(pid_file):
            os.remove(pid_file)
