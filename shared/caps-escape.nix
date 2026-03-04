# Caps Lock → Escape at kernel level (works in console and Wayland)
{ ... }: {
  services.udev.extraHwdb = ''
    # HID keyboards (USB, internal Apple, etc.)
    evdev:input:*
     KEYBOARD_KEY_70039=key_esc

    # AT/PS2 keyboards (ThinkPad internal, etc.)
    evdev:atkbd:*
     KEYBOARD_KEY_3a=key_esc
  '';
}
