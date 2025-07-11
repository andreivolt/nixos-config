{ config, pkgs, ... }:

{
  homebrew.casks = [ "alt-tab" ];

  system.defaults.CustomUserPreferences."com.lwouis.alt-tab-macos" = {
    appearanceStyle = 2;
    appearanceVisibility = 2;
    fadeOutAnimation = true;
    holdShortcut = "\\U2318";
    menubarIconShown = false;
    previewFadeInAnimation = false;
    previewFocusedWindow = true;
    showTitles = 2;
    titleTruncation = 1;
    windowDisplayDelay = 0;
  };
}
