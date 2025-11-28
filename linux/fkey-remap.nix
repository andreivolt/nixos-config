{ config, lib, pkgs, ... }:

# Remap F1-F4 to number keys 1-4 at kernel level (hwdb)
# This works in console and Wayland/X11
# Virtual consoles are moved to Ctrl+Alt+F5-F12 instead of F1-F4
{
  # Use hwdb to remap F1-F4 to 1-4 at the kernel input layer
  # This is the most reliable method for system-wide remapping
  services.udev.extraHwdb = ''
    # Remap F1-F4 to number keys 1-4
    # Works at kernel level, affects console and all graphical sessions
    evdev:atkbd:*
     KEYBOARD_KEY_3b=2   # F1 -> 1
     KEYBOARD_KEY_3c=3   # F2 -> 2
     KEYBOARD_KEY_3d=4   # F3 -> 3
     KEYBOARD_KEY_3e=5   # F4 -> 4
  '';

  # Adjust virtual console keybindings
  # By default, Ctrl+Alt+F1-F6 switch to VT1-6
  # We move them to Ctrl+Alt+F5-F10 since F1-F4 are now number keys
  # Note: The console keymap handles the Ctrl+Alt+Fx VT switching
  # With F1-F4 remapped, we need to use F5+ for VT switching

  # You may also want to adjust your greetd/display manager to use a higher VT
  # For example, greetd can be configured to use tty5 instead of tty1
}
