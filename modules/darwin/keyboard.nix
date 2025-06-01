{...}: {
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
    # swapLeftCommandAndLeftAlt = true; # TODO
  };

  system.defaults.NSGlobalDomain = {
    # Repeat character while key held instead of showing character accents menu
    ApplePressAndHoldEnabled = false;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    AppleKeyboardUIMode = 3; # Full keyboard access in dialogs
  };
}