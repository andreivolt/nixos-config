{...}: {
  system.defaults.trackpad = {
    TrackpadRightClick = true;
    Clicking = true;
    TrackpadThreeFingerDrag = true;
  };

  system.defaults.NSGlobalDomain = {
    "com.apple.trackpad.enableSecondaryClick" = true;
  };

  system.defaults.CustomSystemPreferences.NSGlobalDomain = {
    "com.apple.trackpad".scaling = 1.5;
  };

  system.defaults.CustomUserPreferences."com.apple.AppleMultitouchTrackpad".DragLock = true;
}