{ config, lib, pkgs, ... }:

# Remap F1-F4 to number keys 1-4 at kernel level (hwdb)
# This works in console and Wayland/X11
# Virtual consoles are moved to Ctrl+Alt+F5-F12 instead of F1-F4
{
  # Create hwdb file directly in /etc/udev/hwdb.d/
  # services.udev.extraHwdb doesn't seem to work reliably, so we use environment.etc
  environment.etc."udev/hwdb.d/99-fkey-remap.hwdb".text = ''
    # Remap F1-F4 to number keys 1-4 (AZERTY keyboard)
    # Works at kernel level, affects console and all graphical sessions
    # On AZERTY, these keycodes produce: 1=&, 2=é, 3=", 4='
    # With Shift: 1, 2, 3, 4
    # Scancodes verified for ThinkPad AT keyboard
    evdev:atkbd:*
     KEYBOARD_KEY_3b=key_1
     KEYBOARD_KEY_3c=key_2
     KEYBOARD_KEY_3d=key_3
     KEYBOARD_KEY_3e=key_4
  '';
}
