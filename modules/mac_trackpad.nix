{
  system.defaults.trackpad = {
    TrackpadRightClick = true;
    Clicking = true; # TODO not working
    TrackpadThreeFingerDrag = true;
  };

  system.defaults.NSGlobalDomain."com.apple.trackpad.enableSecondaryClick" = true;

  # set trackpad speed
  system.defaults.CustomSystemPreferences.NSGlobalDomain."com.apple.trackpad".scaling = 1.5;
}
