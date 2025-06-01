{...}: {
  system.defaults.NSGlobalDomain = {
    # Sound settings
    "com.apple.sound.beep.feedback" = 0;
    # "com.apple.sound.beep.volume" = 0.5;

    # Font and appearance
    AppleFontSmoothing = 0;
    AppleInterfaceStyle = "Dark";

    # Finder and file handling
    AppleScrollerPagingBehavior = true;
    AppleShowAllExtensions = true;
    NSNavPanelExpandedStateForSaveMode = true;
    # AppleActionOnDoubleClick = "Maximize"; # TODO

    # Window behavior
    NSWindowResizeTime = 0.001; # faster window resizing

    # Text input
    NSAutomaticQuoteSubstitutionEnabled = false; # disable smart quotes
  };

  system.defaults.CustomSystemPreferences.NSGlobalDomain = {
    NSTextInsertionPointBlinkPeriodOn = 200;
    NSTextInsertionPointBlinkPeriodOff = 200;
    NSToolbarTitleViewRolloverDelay = 0;
  };
}