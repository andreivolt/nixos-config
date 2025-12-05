{ config, lib, pkgs, ... }:

# Remap F1-F4 to number keys 1-4 at kernel level (hwdb)
# Caps->Escape is in profiles/core.nix (shared across machines)
{
  services.udev.extraHwdb = ''
    evdev:atkbd:*
     KEYBOARD_KEY_3b=key_1
     KEYBOARD_KEY_3c=key_2
     KEYBOARD_KEY_3d=key_3
     KEYBOARD_KEY_3e=key_4
  '';
}
