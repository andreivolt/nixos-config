{
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
    # swapLeftCommandAndLeftAlt = true; # TODO
  };

  system.defaults.NSGlobalDomain = {
    # repeat character while key held instead of showing character accents menu
    ApplePressAndHoldEnabled = false;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
  };
}
